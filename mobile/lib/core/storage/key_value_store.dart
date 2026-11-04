import 'package:shared_preferences/shared_preferences.dart';

/// Small wrapper over SharedPreferences for non-secret data (cart, language, cache).
class KeyValueStore {
  KeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const [];
  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
  Iterable<String> keysWithPrefix(String prefix) => _prefs.getKeys().where((k) => k.startsWith(prefix));
}
