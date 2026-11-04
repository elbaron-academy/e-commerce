import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../domain/chat.dart';
import 'unread_cubit.dart';

enum ChatLoad { loading, ready, failed }

enum Receipt { sending, failed, sent, seen }

/// A message on screen: from the server, or one of ours still being sent.
class ChatItem extends Equatable {
  const ChatItem.server(this.message) : localKey = null, sending = false, photo = null, error = null;

  const ChatItem.local({
    required this.message,
    required String this.localKey,
    required this.sending,
    this.photo,
    this.error,
  });

  final ChatMessage message;

  /// Set while the message only exists on the phone.
  final String? localKey;
  final bool sending;
  final ChatPhoto? photo;

  /// Why sending failed, when the server said (e.g. the photo is too large).
  final String? error;

  bool get isLocal => localKey != null;
  bool get failed => isLocal && !sending;

  ChatItem retrying() => ChatItem.local(message: message, localKey: localKey!, sending: true, photo: photo);

  ChatItem failedWith(String? error) =>
      ChatItem.local(message: message, localKey: localKey!, sending: false, photo: photo, error: error);

  @override
  List<Object?> get props => [message.id, localKey, sending, error];
}

class ChatState extends Equatable {
  const ChatState({
    this.load = ChatLoad.loading,
    this.items = const [],
    this.conversation,
    this.hasOlder = false,
    this.loadingOlder = false,
  });

  final ChatLoad load;

  /// Server messages oldest first, then ours that are still sending.
  final List<ChatItem> items;
  final ChatConversation? conversation;
  final bool hasOlder;
  final bool loadingOlder;

  int get lastServerId => items.where((i) => !i.isLocal).fold(0, (max, i) => i.message.id > max ? i.message.id : max);

  ChatState copyWith({
    ChatLoad? load,
    List<ChatItem>? items,
    ChatConversation? conversation,
    bool? hasOlder,
    bool? loadingOlder,
  }) => ChatState(
    load: load ?? this.load,
    items: items ?? this.items,
    conversation: conversation ?? this.conversation,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );

  @override
  List<Object?> get props => [
    load,
    items,
    conversation?.id,
    conversation?.isOpen,
    conversation?.staffLastRead,
    conversation?.customerLastRead,
    hasOlder,
    loadingOlder,
  ];
}

/// The customer's support chat: loads, polls every few seconds while on screen,
/// sends with an optimistic bubble (retry on failure) and keeps read receipts.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository, this._unread, {this.pollEvery = const Duration(seconds: 3)}) : super(const ChatState());

  final SupportRepository _repository;
  final SupportUnreadCubit _unread;
  final Duration pollEvery;

  final _incoming = StreamController<List<ChatMessage>>.broadcast();
  Timer? _timer;
  bool _foreground = true;
  bool _polling = false;
  int _ticks = 0;
  int _localSeq = 0;

  /// New messages from the server, so the screen can scroll or show "new messages".
  Stream<List<ChatMessage>> get incoming => _incoming.stream;

  /// Loads the chat and starts polling: every [pollEvery] in the foreground, 5× slower in the background.
  Future<void> start() async {
    await load();
    _timer ??= Timer.periodic(pollEvery, (_) {
      _ticks += 1;
      if (_foreground || _ticks % 5 == 0) poll();
    });
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (foreground) {
      poll();
      markRead();
    }
  }

  Future<void> load() async {
    emit(state.copyWith(load: ChatLoad.loading));
    try {
      final snapshot = await _repository.chat();
      if (isClosed) return;
      emit(
        ChatState(
          load: ChatLoad.ready,
          items: [for (final m in snapshot.messages) ChatItem.server(m), ...state.items.where((i) => i.isLocal)],
          conversation: snapshot.conversation,
          hasOlder: snapshot.hasOlder,
        ),
      );
      _unread.set(snapshot.unread);
      await markRead();
    } on ApiException {
      if (!isClosed) emit(state.copyWith(load: ChatLoad.failed));
    }
  }

  /// Fetches messages newer than the last one we have. Returns the new ones.
  Future<List<ChatMessage>> poll() async {
    if (_polling || state.load != ChatLoad.ready) return const [];
    _polling = true;
    try {
      final snapshot = await _repository.chat(after: state.lastServerId);
      if (isClosed) return const [];
      final fresh = _merge(snapshot.messages, conversation: snapshot.conversation);
      _unread.set(snapshot.unread);
      if (fresh.isNotEmpty) {
        _incoming.add(fresh);
        if (_foreground) await markRead();
      }
      return fresh;
    } on ApiException {
      return const [];
    } finally {
      _polling = false;
    }
  }

  Future<void> loadOlder() async {
    final first = state.items.where((i) => !i.isLocal).firstOrNull;
    if (first == null || state.loadingOlder || !state.hasOlder) return;
    emit(state.copyWith(loadingOlder: true));
    try {
      final snapshot = await _repository.chat(before: first.message.id);
      if (isClosed) return;
      _merge(snapshot.messages);
      emit(state.copyWith(hasOlder: snapshot.hasOlder, loadingOlder: false));
    } on ApiException {
      if (!isClosed) emit(state.copyWith(loadingOlder: false));
    }
  }

  void send({required String body, ChatPhoto? photo, ChatOrderRef? order}) {
    final text = body.trim();
    if (text.isEmpty && photo == null) return;
    _localSeq += 1;
    final item = ChatItem.local(
      localKey: 'local-$_localSeq',
      sending: true,
      photo: photo,
      message: ChatMessage(
        id: -_localSeq,
        conversation: state.conversation?.id ?? 0,
        isEvent: false,
        event: '',
        sender: ChatSender.customer,
        senderName: '',
        body: text,
        image: null,
        order: order,
        createdAt: DateTime.now(),
      ),
    );
    emit(state.copyWith(items: [...state.items, item]));
    _deliver(item);
  }

  Future<void> retry(ChatItem item) async {
    if (!item.failed) return;
    final again = item.retrying();
    _replace(item.localKey!, again);
    await _deliver(again);
  }

  void discard(ChatItem item) {
    if (!item.isLocal) return;
    emit(state.copyWith(items: state.items.where((i) => i.localKey != item.localKey).toList()));
  }

  Future<void> _deliver(ChatItem item) async {
    try {
      final message = await _repository.send(
        body: item.message.body,
        photo: item.photo,
        orderId: item.message.order?.id,
      );
      if (isClosed) return;
      emit(state.copyWith(items: state.items.where((i) => i.localKey != item.localKey).toList()));
      _merge([message]);
      // The first message after a closed conversation opens a new one.
      final conversation = state.conversation;
      if (conversation == null || !conversation.isOpen || conversation.id != message.conversation) await poll();
    } on ApiException catch (e) {
      if (isClosed) return;
      // Show the server's reason for bad input; for network trouble just offer a retry.
      final reason = !e.isNetwork && (e.statusCode ?? 500) < 500 && e.statusCode != 401 && e.message.isNotEmpty
          ? e.message
          : null;
      _replace(item.localKey!, item.failedWith(reason));
    }
  }

  void _replace(String key, ChatItem next) {
    emit(state.copyWith(items: [for (final i in state.items) i.localKey == key ? next : i]));
  }

  /// Adds messages we don't have yet, keeping server order. Returns the new ones.
  List<ChatMessage> _merge(List<ChatMessage> incoming, {ChatConversation? conversation}) {
    final known = {
      for (final i in state.items)
        if (!i.isLocal) i.message.id,
    };
    final fresh = incoming.where((m) => !known.contains(m.id)).toList();
    if (fresh.isEmpty && conversation == null) return fresh;
    final server = [...state.items.where((i) => !i.isLocal), for (final m in fresh) ChatItem.server(m)]
      ..sort((a, b) => a.message.id.compareTo(b.message.id));
    emit(
      state.copyWith(
        items: [...server, ...state.items.where((i) => i.isLocal)],
        conversation: _keepReadPointer(conversation),
      ),
    );
    return fresh;
  }

  /// A poll may answer before our read receipt lands; never move our own pointer back.
  ChatConversation? _keepReadPointer(ChatConversation? next) {
    final current = state.conversation;
    if (next == null || current == null || next.id != current.id) return next;
    return next.customerLastRead >= current.customerLastRead
        ? next
        : next.copyWith(customerLastRead: current.customerLastRead);
  }

  /// Tells the server we've seen the support team's latest message.
  Future<void> markRead() async {
    final conversation = state.conversation;
    final latest = state.items.lastWhereOrNull((i) => !i.isLocal && i.message.fromStaff && !i.message.isEvent);
    if (!_foreground || conversation == null || latest == null || latest.message.id <= conversation.customerLastRead) {
      return;
    }
    emit(state.copyWith(conversation: conversation.copyWith(customerLastRead: latest.message.id)));
    _unread.set(0);
    try {
      _unread.set(await _repository.markRead(latest.message.id));
    } on ApiException {
      // The next poll tries again.
    }
  }

  /// ✓ sent, ✓✓ seen by the support team.
  Receipt receipt(ChatItem item) {
    if (item.isLocal) return item.sending ? Receipt.sending : Receipt.failed;
    final conversation = state.conversation;
    if (conversation == null || item.message.conversation != conversation.id) return Receipt.seen;
    return item.message.id <= conversation.staffLastRead ? Receipt.seen : Receipt.sent;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _incoming.close();
    return super.close();
  }
}

extension<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    T? found;
    for (final element in this) {
      if (test(element)) found = element;
    }
    return found;
  }
}
