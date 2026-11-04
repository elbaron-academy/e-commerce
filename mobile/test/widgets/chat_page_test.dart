import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_market/app/di.dart';
import 'package:rocket_market/features/auth/presentation/session_cubit.dart';
import 'package:rocket_market/features/support/domain/chat.dart';
import 'package:rocket_market/features/support/presentation/chat_page.dart';
import 'package:rocket_market/features/support/presentation/unread_cubit.dart';

import '../helpers.dart';

class _Session extends Mock implements SessionCubit {}

void main() {
  late FakeSupport server;

  setUp(() {
    server = FakeSupport();
    final session = _Session();
    when(() => session.stream).thenAnswer((_) => const Stream.empty());
    when(() => session.state).thenReturn(const SessionState());
    sl
      ..registerSingleton<SupportRepository>(server)
      ..registerSingleton<SupportUnreadCubit>(SupportUnreadCubit(server, session));
  });

  tearDown(() => sl.reset());

  testWidgets('shows the welcome card, sends a message and shows a staff reply', (tester) async {
    server.staffReply('أهلاً يا منى، إزاي نقدر نساعدك؟');
    await tester.pumpWidget(BlocProvider.value(value: sl<SupportUnreadCubit>(), child: testApp(const ChatPage())));
    await tester.pumpAndSettle();

    expect(find.text('كلّمنا'), findsOneWidget);
    expect(find.textContaining('أهلاً بيك!'), findsOneWidget);
    expect(find.text('أهلاً يا منى، إزاي نقدر نساعدك؟'), findsOneWidget);
    expect(find.text('Salma'), findsOneWidget);

    final send = find.widgetWithIcon(IconButton, Icons.send_rounded);
    expect(tester.widget<IconButton>(send).onPressed, isNull, reason: 'nothing to send yet');
    await tester.enterText(find.byType(TextField), 'الطلب اتأخر');
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(find.text('الطلب اتأخر'), findsOneWidget);
    expect(server.messages.last.body, 'الطلب اتأخر');
    expect(find.byIcon(Icons.done), findsOneWidget, reason: 'sent, not seen yet');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    // Leave the screen so the poll timer stops.
    await tester.pumpWidget(const SizedBox());
  });
}
