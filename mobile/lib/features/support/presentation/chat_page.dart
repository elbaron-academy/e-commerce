import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/app.dart';
import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../orders/domain/order.dart';
import '../domain/chat.dart';
import 'chat_cubit.dart';
import 'unread_cubit.dart';

/// "Chat with us": the customer's conversation with the Rocket support team.
/// Opened from an order, the first message is sent about that order.
class ChatPage extends StatelessWidget {
  const ChatPage({this.orderId, super.key});

  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(sl(), sl())..start(),
      child: _ChatView(orderId: orderId),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({this.orderId});

  final int? orderId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> with WidgetsBindingObserver {
  static const _maxPhotoBytes = 8 * 1024 * 1024;

  final _text = TextEditingController();
  final _scroll = ScrollController();
  late final ChatCubit _cubit = context.read<ChatCubit>();
  late final SupportUnreadCubit _unread = sl<SupportUnreadCubit>();
  StreamSubscription<List<ChatMessage>>? _incoming;
  ChatPhoto? _photo;
  ChatOrderRef? _order;
  bool _newBelow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unread.chatOpen = true;
    _text.addListener(() => setState(() {}));
    _scroll.addListener(_onScroll);
    _incoming = _cubit.incoming.listen((fresh) {
      // The list is reversed: offset 0 is the newest message.
      final nearBottom = !_scroll.hasClients || _scroll.offset < 120;
      if (!nearBottom && fresh.any((m) => m.fromStaff) && mounted) setState(() => _newBelow = true);
    });
    final orderId = widget.orderId;
    if (orderId != null) {
      sl<OrdersRepository>()
          .detail(orderId)
          .then((o) {
            if (mounted) setState(() => _order = ChatOrderRef(id: o.id, number: o.number));
          })
          .catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unread
      ..chatOpen = false
      ..refresh();
    _incoming?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cubit.setForeground(state == AppLifecycleState.resumed);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_newBelow && _scroll.offset < 60) setState(() => _newBelow = false);
    // Older messages load when you reach the top.
    if (_scroll.position.extentAfter < 300) _cubit.loadOlder();
  }

  void _toBottom() {
    setState(() => _newBelow = false);
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _pickPhoto() async {
    final l10n = context.l10n;
    var source = ImageSource.gallery;
    if (!kIsWeb) {
      final picked = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chatPhotoGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.chatPhotoCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      source = picked;
    }
    try {
      // Resized on the phone first: faster to send, and the server re-encodes anyway.
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxPhotoBytes) {
        showMessage('${l10n.chatPhoto}: ≤ 8 MB');
        return;
      }
      final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
      final mime = file.mimeType ?? (name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
      setState(() => _photo = ChatPhoto(bytes: bytes, name: name, mimeType: mime));
    } catch (_) {
      showMessage(l10n.chatPhotoFailed);
    }
  }

  bool get _canSend => _text.text.trim().isNotEmpty || _photo != null;

  void _submit() {
    if (!_canSend) return;
    _cubit.send(body: _text.text, photo: _photo, order: _order);
    _text.clear();
    setState(() {
      _photo = null;
      _order = null;
    });
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.brand50,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/images/logo.png', excludeFromSemantics: true),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.brand500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.chatTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(
                    l10n.chatSubtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) => switch (state.load) {
                    ChatLoad.loading when state.items.isEmpty => const _ChatSkeleton(),
                    ChatLoad.failed when state.items.isEmpty => ErrorView(
                      error: l10n.commonError,
                      onRetry: _cubit.load,
                    ),
                    _ => _MessageList(state: state, controller: _scroll),
                  },
                ),
                if (_newBelow)
                  PositionedDirectional(
                    bottom: 12,
                    start: 0,
                    end: 0,
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: _toBottom,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        label: Text(l10n.chatNewMessages),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _Composer(
            controller: _text,
            photo: _photo,
            order: _order,
            canSend: _canSend,
            onPickPhoto: _pickPhoto,
            onRemovePhoto: () => setState(() => _photo = null),
            onRemoveOrder: () => setState(() => _order = null),
            onSend: _submit,
          ),
        ],
      ),
    );
  }
}

// ---- Messages ----

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state, required this.controller});

  final ChatState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final today = DateUtils.dateOnly(DateTime.now());
    String dayLabel(DateTime d) {
      final day = DateUtils.dateOnly(d);
      if (day == today) return l10n.chatToday;
      if (day == today.subtract(const Duration(days: 1))) return l10n.chatYesterday;
      return fmt.date(d, 'EEEE d MMMM');
    }

    // Oldest first, then reversed so the list starts at the newest message.
    final rows = <Widget>[
      if (state.hasOlder)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Center(child: SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
        )
      else
        const _Welcome(),
    ];
    DateTime? day;
    ChatItem? previous;
    for (final item in state.items) {
      final d = DateUtils.dateOnly(item.message.createdAt);
      if (d != day) {
        day = d;
        previous = null;
        rows.add(_DayChip(label: dayLabel(item.message.createdAt)));
      }
      if (item.message.isEvent) {
        rows.add(_EventLine(text: l10n.chatClosed));
      } else {
        final first = previous == null || previous.message.sender != item.message.sender || previous.message.isEvent;
        rows.add(_Bubble(key: ValueKey(item.localKey ?? item.message.id), item: item, first: first));
      }
      previous = item;
    }

    final reversed = rows.reversed.toList();
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: reversed.length,
      itemBuilder: (_, index) => reversed[index],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            const Text('💬', style: TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              l10n.chatWelcome,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.chatHours,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
      ),
    ),
  );
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.item, required this.first, super.key});

  final ChatItem item;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ChatCubit>();
    final message = item.message;
    final mine = message.sender == ChatSender.customer;
    final foreground = mine ? Colors.white : AppColors.ink;
    final quiet = mine ? Colors.white.withValues(alpha: 0.75) : AppColors.muted;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.8;
    const r = Radius.circular(18);
    const tail = Radius.circular(6);

    return Padding(
      padding: EdgeInsets.only(top: first ? 8 : 2),
      child: Align(
        alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 520)),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!mine && first)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4, bottom: 2),
                  child: Text(
                    message.senderName.isNotEmpty ? message.senderName : l10n.chatSupport,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brand700),
                  ),
                ),
              Opacity(
                opacity: item.failed ? 0.7 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: mine ? AppColors.brand600 : Colors.white,
                    border: mine ? null : Border.all(color: AppColors.line),
                    borderRadius: BorderRadiusDirectional.only(
                      topStart: r,
                      topEnd: r,
                      bottomStart: mine ? r : tail,
                      bottomEnd: mine ? tail : r,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.order case final order?)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: InkWell(
                              onTap: () => context.push('/orders/${order.id}'),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: mine ? Colors.white.withValues(alpha: 0.2) : AppColors.brand50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 12,
                                      color: mine ? Colors.white : AppColors.brand700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.chatAboutOrder(order.number),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: mine ? Colors.white : AppColors.brand700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (message.image != null || item.photo != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _Photo(image: message.image, local: item.photo),
                          ),
                        if (message.body.isNotEmpty)
                          Text(
                            message.body,
                            textDirection: intl.Bidi.detectRtlDirectionality(message.body)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(color: foreground, fontSize: 14.5, height: 1.45),
                          ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.fmt.date(message.createdAt, 'jm'),
                              style: TextStyle(fontSize: 10, color: quiet),
                            ),
                            if (mine) ...[const SizedBox(width: 4), _ReceiptIcon(receipt: cubit.receipt(item))],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (item.failed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => cubit.retry(item),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.error_outline, size: 16),
                      label: Text(item.error ?? l10n.chatFailed),
                    ),
                    IconButton(
                      onPressed: () => cubit.discard(item),
                      tooltip: l10n.commonDelete,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptIcon extends StatelessWidget {
  const _ReceiptIcon({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quiet = Colors.white.withValues(alpha: 0.75);
    final (icon, color, label) = switch (receipt) {
      Receipt.sending => (Icons.schedule, quiet, l10n.chatSending),
      Receipt.sent => (Icons.done, quiet, l10n.chatSent),
      Receipt.seen => (Icons.done_all, AppColors.brand200, l10n.chatSeen),
      Receipt.failed => (Icons.error_outline, quiet, l10n.chatFailed),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({this.image, this.local});

  final ChatImage? image;
  final ChatPhoto? local;

  @override
  Widget build(BuildContext context) {
    final ratio = image?.aspectRatio ?? 4 / 3;
    const maxHeight = 280.0;
    final width = (MediaQuery.sizeOf(context).width * 0.62).clamp(160.0, 320.0);
    final height = (width / ratio).clamp(80.0, maxHeight);
    final Widget picture = local != null
        ? Image.memory(local!.bytes, fit: BoxFit.cover, width: width, height: height)
        : CachedNetworkImage(
            imageUrl: image!.url,
            fit: BoxFit.cover,
            width: width,
            height: height,
            placeholder: (_, _) => const ColoredBox(color: Color(0x11000000)),
            errorWidget: (_, _, _) => const ColoredBox(
              color: Color(0x11000000),
              child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
            ),
          );
    return Semantics(
      image: true,
      label: context.l10n.chatPhotoMessage,
      button: true,
      child: GestureDetector(
        onTap: () => _open(context),
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: picture),
      ),
    );
  }

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: local != null ? Image.memory(local!.bytes) : CachedNetworkImage(imageUrl: image!.url),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: context.l10n.commonClose,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: Skeleton(width: 240, height: 56)),
        SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerEnd, child: Skeleton(width: 180, height: 40)),
        SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerStart, child: Skeleton(width: 200, height: 48)),
      ],
    ),
  );
}

// ---- Composer ----

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.photo,
    required this.order,
    required this.canSend,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onRemoveOrder,
    required this.onSend,
  });

  final TextEditingController controller;
  final ChatPhoto? photo;
  final ChatOrderRef? order;
  final bool canSend;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onRemoveOrder;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order != null || photo != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      if (order case final order?)
                        Chip(
                          avatar: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.brand700),
                          label: Text(l10n.chatAboutOrder(order.number)),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand700,
                          ),
                          backgroundColor: AppColors.brand50,
                          side: const BorderSide(color: AppColors.brand100),
                          onDeleted: onRemoveOrder,
                          deleteButtonTooltipMessage: l10n.chatRemoveOrder,
                        ),
                      if (photo case final photo?)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(photo.bytes, height: 72, width: 72, fit: BoxFit.cover),
                            ),
                            PositionedDirectional(
                              top: -8,
                              end: -8,
                              child: IconButton.filled(
                                onPressed: onRemovePhoto,
                                tooltip: l10n.chatRemovePhoto,
                                iconSize: 14,
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(backgroundColor: AppColors.ink),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onPickPhoto,
                    tooltip: l10n.chatPhoto,
                    color: AppColors.muted,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.chatPlaceholder,
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: canSend ? onSend : null,
                    tooltip: l10n.chatSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
