import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import 'unread_cubit.dart';

/// Chat icon with the unread badge, for headers.
class ChatButton extends StatelessWidget {
  const ChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<SupportUnreadCubit>().state;
    return IconButton(
      onPressed: () => context.push('/chat'),
      tooltip: context.l10n.chatTitle,
      color: AppColors.brand700,
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        backgroundColor: AppColors.accent500,
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}

/// "Chat with us" card for the account screen.
class ChatTile extends StatelessWidget {
  const ChatTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unread = context.watch<SupportUnreadCubit>().state;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push('/chat'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.chat_bubble_outline, color: AppColors.brand700),
        ),
        title: Text(l10n.chatTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(l10n.chatSubtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unread > 0) Badge(label: Text('$unread'), backgroundColor: AppColors.accent500),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
