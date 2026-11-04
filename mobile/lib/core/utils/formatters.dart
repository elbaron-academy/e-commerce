import 'dart:ui';

import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';

final _number = NumberFormat('#,##0.##', 'en');

/// Money, quantities and dates in the app language, with Latin digits (like the website).
class Fmt {
  const Fmt(this.lang, this.l10n);

  final String lang;
  final AppLocalizations l10n;

  String money(num value) => lang == 'ar' ? '${_number.format(value)} ج.م' : 'EGP ${_number.format(value)}';

  String number(num value) => _number.format(value);

  /// 0.25 → "250 جم", 1.5 → "1.5 كجم", 3 → "3".
  String qty(num value, {required bool byWeight}) {
    if (!byWeight) return _number.format(value);
    return value < 1
        ? '${_number.format((value * 1000).round())} ${l10n.unitsG}'
        : '${_number.format(value)} ${l10n.unitsKg}';
  }

  String date(DateTime value, String pattern) => DateFormat(pattern, lang).format(value.toLocal());

  /// "13:00" → "1:00 م" / "1:00 PM".
  String time(String hhmm) {
    final parts = hhmm.split(':');
    final at = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat(at.minute == 0 ? 'h a' : 'h:mm a', lang).format(at);
  }
}

/// "#E3F3DC" → Color.
Color parseHexColor(String? hex, {Color fallback = const Color(0xFFEEF2EF)}) {
  final value = (hex ?? '').replaceFirst('#', '');
  if (value.length != 6) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(0xFF000000 | parsed);
}
