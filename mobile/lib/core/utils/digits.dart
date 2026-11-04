const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const _easternArabic = '۰۱۲۳۴۵۶۷۸۹';
final _egyptianMobile = RegExp(r'^01[0125]\d{8}$');

/// "٠١٢٣" → "0123" (Arabic keyboards type Arabic-Indic digits).
String toLatinDigits(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    var digit = _arabicIndic.indexOf(ch);
    if (digit < 0) digit = _easternArabic.indexOf(ch);
    out.write(digit >= 0 ? '$digit' : ch);
  }
  return out.toString();
}

/// "+20 100 123 4567" or "٠١٠٠١٢٣٤٥٦٧" → "01001234567".
String normalizePhone(String input) {
  var digits = toLatinDigits(input).replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('20') && digits.length >= 12) digits = '0${digits.substring(2)}';
  return digits.length > 11 ? digits.substring(0, 11) : digits;
}

bool isValidEgyptianMobile(String phone) => _egyptianMobile.hasMatch(phone);
