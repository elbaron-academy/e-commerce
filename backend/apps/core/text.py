"""Text helpers for Arabic/English search and phone numbers (BE-303)."""

import re

_DIACRITICS = re.compile("[ً-ٰٟ]")
_ALEF = re.compile("[أإآٱ]")
_NON_WORD = re.compile(r"[^\w\s]")
_SPACES = re.compile(r"\s+")
_ARABIC_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹", "01234567890123456789")


def normalize_text(value: str) -> str:
    """أ/إ/آ → ا, ة → ه, ى → ي, drop diacritics and tatweel, lowercase."""
    value = (value or "").lower()
    value = _DIACRITICS.sub("", value).replace("ـ", "")
    value = _ALEF.sub("ا", value)
    value = value.replace("ة", "ه").replace("ى", "ي").replace("ؤ", "و").replace("ئ", "ي")
    value = _NON_WORD.sub(" ", value).replace("_", " ")
    return _SPACES.sub(" ", value).strip()


def strip_article(word: str) -> str:
    """Removes the Arabic definite article so "الموز" matches "موز"."""
    return word[2:] if len(word) > 3 and word.startswith("ال") else word


def search_words(*parts: str) -> list[str]:
    words = normalize_text(" ".join(p for p in parts if p)).split()
    return list(dict.fromkeys([*words, *(strip_article(w) for w in words)]))


def query_tokens(query: str) -> list[str]:
    return [strip_article(w) for w in normalize_text(query).split()]


def to_latin_digits(value: str) -> str:
    return (value or "").translate(_ARABIC_DIGITS)


def normalize_phone(value: str) -> str:
    """'+20 100 123 4567' or '٠١٠٠١٢٣٤٥٦٧' → '01001234567'."""
    digits = re.sub(r"\D", "", to_latin_digits(value))
    if digits.startswith("20") and len(digits) == 12:
        digits = "0" + digits[2:]
    return digits


def levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    previous = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        current = [i]
        for j, cb in enumerate(b, 1):
            current.append(min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (ca != cb)))
        previous = current
    return previous[-1]
