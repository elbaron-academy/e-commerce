import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/digits.dart';
import '../domain/auth.dart';
import 'session_cubit.dart';

enum LoginStep { phone, code, name }

class LoginState extends Equatable {
  const LoginState({
    this.step = LoginStep.phone,
    this.phone = '',
    this.busy = false,
    this.error,
    this.invalidPhone = false,
    this.resendIn = 0,
  });

  final LoginStep step;
  final String phone;
  final bool busy;
  final Object? error;
  final bool invalidPhone;
  final int resendIn;

  LoginState copyWith({
    LoginStep? step,
    String? phone,
    bool? busy,
    Object? Function()? error,
    bool? invalidPhone,
    int? resendIn,
  }) => LoginState(
    step: step ?? this.step,
    phone: phone ?? this.phone,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
    invalidPhone: invalidPhone ?? false,
    resendIn: resendIn ?? this.resendIn,
  );

  @override
  List<Object?> get props => [step, phone, busy, error, invalidPhone, resendIn];
}

/// Phone number → SMS code → (first time) name.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth, this._session) : super(const LoginState());

  final AuthRepository _auth;
  final SessionCubit _session;
  Timer? _timer;
  User? _user;

  Future<void> sendCode(String input) async {
    final phone = normalizePhone(input);
    if (!isValidEgyptianMobile(phone)) {
      emit(state.copyWith(invalidPhone: true, error: () => null));
      return;
    }
    emit(state.copyWith(phone: phone, busy: true, error: () => null));
    try {
      final resendIn = await _auth.sendCode(phone);
      emit(state.copyWith(step: LoginStep.code, busy: false, resendIn: resendIn));
      _startCountdown();
    } catch (error) {
      emit(state.copyWith(busy: false, error: () => error));
    }
  }

  Future<void> verify(String input) async {
    final code = toLatinDigits(input).replaceAll(RegExp(r'\D'), '');
    if (code.length < 4 || state.busy) return;
    emit(state.copyWith(busy: true, error: () => null));
    try {
      final result = await _auth.verifyCode(state.phone, code);
      _user = result.user;
      if (result.isNew) {
        emit(state.copyWith(step: LoginStep.name, busy: false));
      } else {
        _session.signedIn(result.user);
      }
    } catch (error) {
      emit(state.copyWith(busy: false, error: () => error));
    }
  }

  Future<void> finish(String name) async {
    var user = _user!;
    if (name.trim().isNotEmpty) {
      emit(state.copyWith(busy: true));
      try {
        user = await _auth.updateProfile(name: name.trim());
      } catch (_) {
        // The name can be added later from the account screen.
      }
    }
    _session.signedIn(user);
  }

  void changePhone() {
    _timer?.cancel();
    emit(const LoginState());
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.resendIn - 1;
      emit(state.copyWith(resendIn: left < 0 ? 0 : left));
      if (left <= 0) timer.cancel();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(sl(), sl()),
      child: BlocListener<SessionCubit, SessionState>(
        listenWhen: (previous, current) => !previous.isLoggedIn && current.isLoggedIn,
        listener: (context, _) => _leave(context),
        child: const _LoginView(),
      ),
    );
  }

  /// Back to where the customer came from (e.g. checkout).
  static void _leave(BuildContext context) {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];
    if (context.canPop()) context.pop();
    if (redirect != null && redirect != '/login') openLink(context, redirect);
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LoginCubit>();
    return Scaffold(
      appBar: AppBar(),
      body: BlocConsumer<LoginCubit, LoginState>(
        listenWhen: (a, b) => a.step != b.step,
        listener: (_, state) {
          if (state.step == LoginStep.code) _code.clear();
        },
        builder: (context, state) {
          final error = state.invalidPhone
              ? l10n.authInvalidPhone
              : (state.error == null ? null : errorText(state.error!, l10n));
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/logo.png', width: 64, height: 64),
                ),
              ),
              const SizedBox(height: 20),
              ...switch (state.step) {
                LoginStep.phone => [
                  Text(l10n.authTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l10n.authSubtitle, style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  Text(l10n.authPhone, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phone,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    style: const TextStyle(fontSize: 20, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      hintText: l10n.authPhonePlaceholder,
                      hintTextDirection: TextDirection.ltr,
                    ),
                    onSubmitted: cubit.sendCode,
                  ),
                ],
                LoginStep.code => [
                  Text(l10n.authCodeTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l10n.authCodeSent(state.phone), style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  AutofillGroup(
                    child: TextField(
                      controller: _code,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      maxLength: 4,
                      // SMS code autofill on iOS and Android keyboards (MOB-102).
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [_DigitsFormatter()],
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 18),
                      decoration: const InputDecoration(counterText: '', hintText: '••••'),
                      onChanged: (value) {
                        if (value.length == 4) cubit.verify(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.accent50, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      l10n.authDemoHint,
                      style: const TextStyle(color: AppColors.accent700, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
                LoginStep.name => [
                  Text(l10n.authNameTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  Text(l10n.authName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    autofillHints: const [AutofillHints.name],
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              },
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.busy
                    ? null
                    : switch (state.step) {
                        LoginStep.phone => () => cubit.sendCode(_phone.text),
                        LoginStep.code => () => cubit.verify(_code.text),
                        LoginStep.name => () => cubit.finish(_name.text),
                      },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: state.busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(switch (state.step) {
                        LoginStep.phone => l10n.authSendCode,
                        LoginStep.code => l10n.authVerify,
                        LoginStep.name => l10n.authFinish,
                      }),
              ),
              if (state.step == LoginStep.code)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: cubit.changePhone, child: Text(l10n.authChangePhone)),
                    if (state.resendIn > 0)
                      Text(
                        l10n.authResendIn('${state.resendIn}'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      )
                    else
                      TextButton(
                        onPressed: state.busy ? null : () => cubit.sendCode(state.phone),
                        child: Text(l10n.authResend),
                      ),
                  ],
                ),
              if (state.step == LoginStep.name)
                TextButton(onPressed: () => cubit.finish(''), child: Text(l10n.authSkip)),
            ],
          );
        },
      ),
    );
  }
}

/// Keeps only digits and converts Arabic-Indic digits ("١٢٣٤" → "1234").
class _DigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = toLatinDigits(newValue.text).replaceAll(RegExp(r'\D'), '');
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
