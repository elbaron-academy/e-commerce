import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:rocket_market/core/l10n/l10n.dart';
import 'package:rocket_market/core/utils/digits.dart';
import 'package:rocket_market/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
  });

  Fmt fmt(String lang) => Fmt(lang, lookupAppLocalizations(Locale(lang)));

  test('money uses Latin digits and the local currency label', () {
    expect(fmt('ar').money(32), '32 ج.م');
    expect(fmt('ar').money(232.5), '232.5 ج.م');
    expect(fmt('en').money(1440), 'EGP 1,440');
  });

  test('quantities: grams under 1 kg, kg above, plain numbers for units', () {
    expect(fmt('ar').qty(0.5, byWeight: true), '500 جم');
    expect(fmt('ar').qty(1.25, byWeight: true), '1.25 كجم');
    expect(fmt('en').qty(0.75, byWeight: true), '750 g');
    expect(fmt('en').qty(3, byWeight: false), '3');
  });

  test('times and dates', () {
    expect(fmt('en').time('13:00'), '1 PM');
    expect(fmt('ar').time('09:30'), '9:30 ص');
    expect(fmt('ar').date(DateTime(2026, 11, 4), 'd MMMM'), '4 نوفمبر');
  });

  test('hex colors', () {
    expect(parseHexColor('#E3F3DC'), const Color(0xFFE3F3DC));
    expect(parseHexColor('nope'), const Color(0xFFEEF2EF));
  });

  test('Arabic digits and phone numbers', () {
    expect(toLatinDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    expect(normalizePhone('+20 100 123 4567'), '01001234567');
    expect(normalizePhone('٠١٠٩٨٧٦٥٤٣٢'), '01098765432');
    expect(isValidEgyptianMobile('01098765432'), isTrue);
    expect(isValidEgyptianMobile('01398765432'), isFalse);
    expect(isValidEgyptianMobile('0109876543'), isFalse);
  });
}
