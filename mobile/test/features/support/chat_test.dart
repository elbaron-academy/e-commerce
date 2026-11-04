import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_market/core/network/api_exception.dart';
import 'package:rocket_market/features/auth/domain/auth.dart';
import 'package:rocket_market/features/auth/presentation/session_cubit.dart';
import 'package:rocket_market/features/support/data/support_repository_impl.dart';
import 'package:rocket_market/features/support/domain/chat.dart';
import 'package:rocket_market/features/support/presentation/chat_cubit.dart';
import 'package:rocket_market/features/support/presentation/unread_cubit.dart';

import '../../helpers.dart';

class _Session extends Mock implements SessionCubit {}

void main() {
  late FakeSupport server;
  late SupportUnreadCubit unread;
  late _Session session;

  setUp(() {
    server = FakeSupport();
    session = _Session();
    when(() => session.stream).thenAnswer((_) => const Stream.empty());
    when(() => session.state).thenReturn(
      const SessionState(
        user: User(id: 1, phone: '01011112222', name: 'Mona', email: '', language: 'ar'),
      ),
    );
    unread = SupportUnreadCubit(server, session);
  });

  tearDown(() => unread.close());

  ChatCubit cubit() => ChatCubit(server, unread, pollEvery: const Duration(hours: 1));

  group('mapping', () {
    test('reads the chat the API returns', () {
      final snapshot = chatSnapshotFromJson(fixture('support_chat'));
      expect(snapshot.conversation!.id, 4);
      expect(snapshot.conversation!.isOpen, isTrue);
      expect(snapshot.messages.map((m) => m.sender), [
        ChatSender.customer,
        ChatSender.customer,
        ChatSender.staff,
        ChatSender.staff,
        ChatSender.staff,
        ChatSender.customer,
      ]);
      final photo = snapshot.messages[1].image!;
      expect(photo.url, startsWith('http://localhost:8000/media/support/'));
      expect(photo.aspectRatio, closeTo(4 / 3, 0.01));
      expect(snapshot.messages[2].senderName, 'Salma');
      final closed = snapshot.messages[4];
      expect(closed.isEvent, isTrue);
      expect(closed.event, 'closed');
      // The last message is in the new conversation opened after closing.
      expect(snapshot.messages.last.conversation, 4);
      expect(snapshot.messages.first.conversation, isNot(4));
    });

    test('reads an order reference', () {
      final json = fixture('support_chat');
      final first = (json['messages'] as List).first as Map<String, dynamic>;
      first['order'] = {'id': 7, 'number': 'RK-000007'};
      final message = chatSnapshotFromJson(json).messages.first;
      expect(message.order!.number, 'RK-000007');
    });
  });

  group('ChatCubit', () {
    test('loads, shows a message right away and swaps in the server copy', () async {
      server.staffReply('أهلاً! تقدر تسألنا عن أي حاجة');
      final chat = cubit();
      await chat.start();
      expect(chat.state.load, ChatLoad.ready);
      expect(chat.state.items, hasLength(1));
      expect(unread.state, 0, reason: 'opening the chat reads the reply');
      expect(server.customerLastRead, server.messages.last.id);

      server.sendGate = Completer();
      chat.send(
        body: '  طلبي اتأخر  ',
        order: const ChatOrderRef(id: 9, number: 'RK-9'),
      );
      final pending = chat.state.items.last;
      expect(pending.isLocal, isTrue);
      expect(pending.message.body, 'طلبي اتأخر');
      expect(chat.receipt(pending), Receipt.sending);

      server.sendGate!.complete();
      await pumpEventQueue();
      final sent = chat.state.items.last;
      expect(sent.isLocal, isFalse);
      expect(sent.message.order!.id, 9);
      expect(chat.receipt(sent), Receipt.sent);
      expect(chat.state.items, hasLength(2));
      await chat.close();
    });

    test('a failed message can be retried or discarded', () async {
      final chat = cubit();
      await chat.start();
      server.failNextSend = const ApiException(message: '', code: 'network');
      chat.send(body: 'مرحبا');
      await pumpEventQueue();
      final failed = chat.state.items.single;
      expect(failed.failed, isTrue);
      expect(failed.error, isNull, reason: 'network trouble only offers a retry');
      expect(chat.receipt(failed), Receipt.failed);

      await chat.retry(failed);
      expect(chat.state.items.single.isLocal, isFalse);

      server.failNextSend = const ApiException(
        message: 'الصورة أكبر من 8 ميجا.',
        code: 'image_too_large',
        statusCode: 400,
      );
      chat.send(
        body: '',
        photo: ChatPhoto(bytes: Uint8List(4), name: 'big.jpg'),
      );
      await pumpEventQueue();
      final rejected = chat.state.items.last;
      expect(rejected.error, 'الصورة أكبر من 8 ميجا.');
      chat.discard(rejected);
      expect(chat.state.items, hasLength(1));
      await chat.close();
    });

    test('polling adds replies once, updates ✓✓ and the unread badge', () async {
      final chat = cubit();
      await chat.start();
      chat.send(body: 'فين الطلب؟');
      await pumpEventQueue();
      final mine = chat.state.items.single;

      server.staffReads();
      server.staffReply('المندوب في الطريق');
      final incoming = expectLater(chat.incoming, emits(hasLength(1)));
      chat.setForeground(false);
      final fresh = await chat.poll();
      expect(fresh.single.body, 'المندوب في الطريق');
      await incoming;
      expect(chat.receipt(chat.state.items.firstWhere((i) => i.message.id == mine.message.id)), Receipt.seen);
      expect(unread.state, 1, reason: 'in the background the reply stays unread');

      expect(await chat.poll(), isEmpty, reason: 'no duplicates');
      expect(chat.state.items, hasLength(2));

      chat.setForeground(true);
      await pumpEventQueue();
      expect(unread.state, 0);
      expect(server.customerLastRead, server.messages.last.id);
      await chat.close();
    });

    test('the unread badge only checks when signed in and the chat is closed', () async {
      server.staffReply('رد');
      await unread.refresh();
      expect(unread.state, 1);
      unread.chatOpen = true;
      server.staffReply('رد تاني');
      await unread.refresh();
      expect(unread.state, 1);
      unread.chatOpen = false;
      when(() => session.state).thenReturn(const SessionState());
      await unread.refresh();
      expect(unread.state, 1, reason: 'signed out: no request');
    });
  });
}
