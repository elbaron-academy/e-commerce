import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/session_cubit.dart';
import '../domain/chat.dart';

/// Unread replies from the support team, for the badges on the chat buttons.
/// Checks every minute while the app is in the foreground and someone is signed in.
class SupportUnreadCubit extends Cubit<int> {
  SupportUnreadCubit(this._repository, this._session, {this.every = const Duration(minutes: 1)}) : super(0) {
    _sessionSub = _session.stream.listen((s) => s.isLoggedIn ? refresh() : emit(0));
  }

  final SupportRepository _repository;
  final SessionCubit _session;
  final Duration every;
  late final StreamSubscription<SessionState> _sessionSub;
  Timer? _timer;
  bool _paused = false;

  /// The chat screen keeps the count itself while it's open.
  bool chatOpen = false;

  void start() {
    refresh();
    _timer ??= Timer.periodic(every, (_) => refresh());
  }

  void pause() => _paused = true;

  void resume() {
    _paused = false;
    refresh();
  }

  void set(int unread) {
    if (!isClosed) emit(unread);
  }

  Future<void> refresh() async {
    if (_paused || chatOpen || !_session.state.isLoggedIn) return;
    try {
      set(await _repository.unread());
    } on ApiException {
      // Keep the last count on a network blip.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _sessionSub.cancel();
    return super.close();
  }
}
