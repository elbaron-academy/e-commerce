import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._tokens, this._store);

  static const _userKey = 'rk_user';

  final ApiClient _api;
  final TokenStore _tokens;
  final KeyValueStore _store;

  @override
  bool get hasSession => _tokens.hasSession;

  @override
  User? get cachedUser {
    final raw = _store.getString(_userKey);
    if (raw == null || !hasSession) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<User> _remember(User user) async {
    await _store.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<int> sendCode(String phone) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/otp/send/', data: {'phone': phone});
    return (data['resend_in'] as int?) ?? 60;
  }

  @override
  Future<({User user, bool isNew})> verifyCode(String phone, String code) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/otp/verify/', data: {'phone': phone, 'code': code});
    await _tokens.save(access: data['access'] as String, refresh: data['refresh'] as String);
    final user = await _remember(User.fromJson(data['user'] as Map<String, dynamic>));
    return (user: user, isNew: data['is_new'] as bool? ?? false);
  }

  @override
  Future<User> me() async => _remember(User.fromJson(await _api.get<Map<String, dynamic>>('/me/')));

  @override
  Future<User> updateProfile({String? name, String? email, String? language}) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/me/',
      data: {'name': ?name, 'email': ?email, 'language': ?language},
    );
    return _remember(User.fromJson(data));
  }

  @override
  Future<void> logout() async {
    await _tokens.clear();
    await _store.remove(_userKey);
  }
}
