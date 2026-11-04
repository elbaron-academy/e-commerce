"""Two-language content: models store `<field>_ar` and `<field>_en` columns."""

from django.utils import translation


def current_lang() -> str:
    return "en" if (translation.get_language() or "ar").startswith("en") else "ar"


def tr(obj, field: str) -> str:
    """The field in the active language, falling back to the other one."""
    lang = current_lang()
    other = "ar" if lang == "en" else "en"
    return getattr(obj, f"{field}_{lang}", "") or getattr(obj, f"{field}_{other}", "") or ""


def t(ar: str, en: str) -> str:
    """Picks a message for the active language."""
    return en if current_lang() == "en" else ar
