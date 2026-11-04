import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT tokens in the platform keychain/keystore (MOB-103), cached in memory
/// so the HTTP interceptor can read them synchronously.
class TokenStore {
  TokenStore(this._storage);

  static const _accessKey = 'rk_access';
  static const _refreshKey = 'rk_refresh';

  final FlutterSecureStorage _storage;
  String? _access;
  String? _refresh;

  String? get access => _access;
  String? get refresh => _refresh;
  bool get hasSession => _access != null;

  Future<void> load() async {
    try {
      _access = await _storage.read(key: _accessKey);
      _refresh = await _storage.read(key: _refreshKey);
    } catch (_) {
      // Keychain can be unavailable (e.g. after a device restore): start signed out.
      _access = _refresh = null;
    }
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    _access = _refresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
