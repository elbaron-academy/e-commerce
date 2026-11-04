from django.utils import translation


class QueryLanguageMiddleware:
    """
    Lets clients pick the language with ?lang=ar|en (runs after LocaleMiddleware).
    The storefront sends it on every request so caches keep each language apart.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        lang = request.GET.get("lang")
        if lang in ("ar", "en"):
            translation.activate(lang)
            request.LANGUAGE_CODE = lang
        response = self.get_response(request)
        response.headers.setdefault("Content-Language", translation.get_language() or "ar")
        return response
