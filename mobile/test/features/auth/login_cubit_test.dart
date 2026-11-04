import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rocket_market/core/network/api_exception.dart';
import 'package:rocket_market/features/auth/domain/auth.dart';
import 'package:rocket_market/features/auth/presentation/login_page.dart';
import 'package:rocket_market/features/auth/presentation/session_cubit.dart';

class MockAuth extends Mock implements AuthRepository {}

void main() {
  const newUser = User(id: 1, phone: '01098765432', name: '', email: '', language: 'ar');
  late MockAuth auth;
  late SessionCubit session;

  setUp(() {
    auth = MockAuth();
    when(() => auth.cachedUser).thenReturn(null);
    when(() => auth.hasSession).thenReturn(false);
    session = SessionCubit(auth);
  });

  blocTest<LoginCubit, LoginState>(
    'rejects invalid phone numbers without calling the API',
    build: () => LoginCubit(auth, session),
    act: (c) => c.sendCode('0123'),
    expect: () => [isA<LoginState>().having((s) => s.invalidPhone, 'invalidPhone', isTrue)],
    verify: (_) => verifyNever(() => auth.sendCode(any())),
  );

  blocTest<LoginCubit, LoginState>(
    'accepts Arabic digits and moves to the code step',
    setUp: () => when(() => auth.sendCode('01098765432')).thenAnswer((_) async => 60),
    build: () => LoginCubit(auth, session),
    act: (c) => c.sendCode('٠١٠٩٨٧٦٥٤٣٢'),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<LoginState>().having((s) => s.busy, 'busy', isTrue),
      isA<LoginState>().having((s) => s.step, 'step', LoginStep.code).having((s) => s.resendIn, 'resendIn', 60),
    ],
  );

  test('new customers set their name, then the session starts', () async {
    when(() => auth.sendCode(any())).thenAnswer((_) async => 60);
    when(() => auth.verifyCode('01098765432', '1234')).thenAnswer((_) async => (user: newUser, isNew: true));
    when(() => auth.updateProfile(name: 'Mona'))
        .thenAnswer((_) async => const User(id: 1, phone: '01098765432', name: 'Mona', email: '', language: 'ar'));
    final cubit = LoginCubit(auth, session);
    await cubit.sendCode('01098765432');
    await cubit.verify('١٢٣٤');
    expect(cubit.state.step, LoginStep.name);
    expect(session.state.isLoggedIn, isFalse);
    await cubit.finish(' Mona ');
    expect(session.state.user!.name, 'Mona');
    await cubit.close();
  });

  test('returning customers are signed in right after the code', () async {
    when(() => auth.sendCode(any())).thenAnswer((_) async => 60);
    when(() => auth.verifyCode(any(), any())).thenAnswer(
      (_) async =>
          (user: const User(id: 2, phone: '01011112222', name: 'Ali', email: '', language: 'en'), isNew: false),
    );
    final cubit = LoginCubit(auth, session);
    await cubit.sendCode('01011112222');
    await cubit.verify('1234');
    expect(session.state.user!.name, 'Ali');
    await cubit.close();
  });

  test('shows the server message for a wrong code', () async {
    when(() => auth.sendCode(any())).thenAnswer((_) async => 60);
    when(() => auth.verifyCode(any(), any()))
        .thenThrow(const ApiException(message: 'الكود غلط أو انتهى.', code: 'otp_invalid'));
    final cubit = LoginCubit(auth, session);
    await cubit.sendCode('01011112222');
    await cubit.verify('0000');
    expect((cubit.state.error! as ApiException).message, 'الكود غلط أو انتهى.');
    expect(cubit.state.step, LoginStep.code);
    await cubit.close();
  });
}
