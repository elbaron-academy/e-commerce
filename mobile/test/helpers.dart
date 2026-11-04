import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rocket_market/app/theme.dart';
import 'package:rocket_market/core/l10n/l10n.dart';
import 'package:rocket_market/features/cart/domain/cart.dart';
import 'package:rocket_market/features/cart/domain/cart_repository.dart';
import 'package:rocket_market/core/network/api_exception.dart';
import 'package:rocket_market/features/cart/presentation/cart_cubit.dart';
import 'package:rocket_market/features/support/domain/chat.dart';

/// Real API responses captured from the Django backend.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

List<dynamic> fixtureList(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as List<dynamic>;

/// Cart storage in memory.
class MemoryCartRepository implements CartRepository {
  List<CartLine> lines = [];
  String? coupon;
  int saves = 0;

  @override
  ({List<CartLine> lines, String? coupon}) load() => (lines: lines, coupon: coupon);

  @override
  Future<void> save(List<CartLine> lines, String? coupon) async {
    this.lines = lines;
    this.coupon = coupon;
    saves++;
  }

  @override
  Future<Quote> quote(List<CartItemInput> items, {String? coupon, String? zone, String method = 'delivery'}) =>
      throw UnimplementedError();
}

/// Wraps a widget with theme, localization (Arabic by default) and a cart.
Widget testApp(Widget child, {CartCubit? cart, Locale locale = const Locale('ar')}) => BlocProvider(
  create: (_) => cart ?? CartCubit(MemoryCartRepository()),
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  ),
);

/// In-memory chat server with the same rules as the API.
class FakeSupport implements SupportRepository {
  final messages = <ChatMessage>[];
  ChatConversation? conversation;
  int _id = 100;
  int customerLastRead = 0;
  Completer<void>? sendGate;
  ApiException? failNextSend;

  ChatMessage _message(ChatSender sender, String body, {ChatOrderRef? order}) {
    conversation ??= const ChatConversation(id: 1, isOpen: true, staffLastRead: 0, customerLastRead: 0);
    final m = ChatMessage(
      id: ++_id,
      conversation: conversation!.id,
      isEvent: false,
      event: '',
      sender: sender,
      senderName: sender == ChatSender.staff ? 'Salma' : '',
      body: body,
      image: null,
      order: order,
      createdAt: DateTime(2026, 11, 4, 12, _id % 60),
    );
    messages.add(m);
    return m;
  }

  ChatMessage staffReply(String body) => _message(ChatSender.staff, body);

  void staffReads() => conversation = ChatConversation(
    id: conversation!.id,
    isOpen: true,
    staffLastRead: messages.last.id,
    customerLastRead: customerLastRead,
  );

  int get _unread => messages.where((m) => m.fromStaff && m.id > customerLastRead).length;

  ChatConversation? get _conversation => conversation == null
      ? null
      : ChatConversation(
          id: conversation!.id,
          isOpen: conversation!.isOpen,
          staffLastRead: conversation!.staffLastRead,
          customerLastRead: customerLastRead,
        );

  @override
  Future<ChatSnapshot> chat({int? after, int? before}) async {
    final list = after != null
        ? messages.where((m) => m.id > after).toList()
        : messages.where((m) => before == null || m.id < before).toList();
    return ChatSnapshot(conversation: _conversation, messages: list, hasOlder: false, unread: _unread);
  }

  @override
  Future<ChatMessage> send({required String body, ChatPhoto? photo, int? orderId}) async {
    await sendGate?.future;
    if (failNextSend case final error?) {
      failNextSend = null;
      throw error;
    }
    final m = _message(
      ChatSender.customer,
      body,
      order: orderId == null ? null : ChatOrderRef(id: orderId, number: 'RK-1'),
    );
    customerLastRead = m.id;
    return m;
  }

  @override
  Future<int> markRead(int messageId) async {
    customerLastRead = messageId;
    return _unread;
  }

  @override
  Future<int> unread() async => _unread;
}
