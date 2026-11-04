import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth.dart';

class SessionState extends Equatable {
  const SessionState({this.user, this.expired = false});

  final User? user;

  /// True right after the server rejected an expired session.
  final bool expired;

  bool get isLoggedIn => user != null;

  @override
  List<Object?> get props => [user?.id, user?.name, user?.email, user?.phone, user?.language, expired];
}

/// The signed-in customer, shared by the whole app.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth) : super(SessionState(user: _auth.cachedUser));

  final AuthRepository _auth;

  /// Refreshes the profile from the server (on app start).
  Future<void> refresh() async {
    if (!_auth.hasSession) return;
    try {
      emit(SessionState(user: await _auth.me()));
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
    }
  }

  void signedIn(User user) => emit(SessionState(user: user));

  void updated(User user) => emit(SessionState(user: user));

  Future<void> logout() async {
    await _auth.logout();
    emit(const SessionState());
  }

  /// Called by the HTTP client when the refresh token no longer works.
  Future<void> expired() async {
    final wasLoggedIn = state.isLoggedIn;
    await _auth.logout();
    emit(SessionState(expired: wasLoggedIn));
  }
}
