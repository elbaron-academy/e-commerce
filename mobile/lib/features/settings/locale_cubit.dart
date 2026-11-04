import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/key_value_store.dart';

/// App language: Arabic (default, RTL) or English. Remembered on the device.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._store) : super(Locale(_store.getString(_key) ?? 'ar'));

  static const _key = 'rk_lang';

  final KeyValueStore _store;

  String get languageCode => state.languageCode;

  void toggle() => select(languageCode == 'ar' ? 'en' : 'ar');

  void select(String code) {
    if (code == languageCode) return;
    _store.setString(_key, code);
    emit(Locale(code));
  }
}
