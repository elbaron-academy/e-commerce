"""One error shape for every API error: {"detail": "...", "code": "...", ...}."""

from django.core.exceptions import PermissionDenied
from django.http import Http404
from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.views import exception_handler


class ApiError(APIException):
    """Business-rule error with a translated message and optional extra fields."""

    status_code = status.HTTP_400_BAD_REQUEST
    default_code = "error"

    def __init__(self, detail: str, *, status_code: int | None = None, code: str | None = None, **extra):
        super().__init__(detail=detail, code=code or self.default_code)
        if status_code:
            self.status_code = status_code
        self.code = code or self.default_code
        self.extra = extra


def _first_error(data, prefix=""):
    if isinstance(data, dict):
        for key, value in data.items():
            name = key if key != "non_field_errors" else ""
            return _first_error(value, f"{prefix}.{name}".strip(".") if name else prefix)
    if isinstance(data, list) and data:
        return _first_error(data[0], prefix)
    return str(data), prefix or None


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return None
    if isinstance(exc, ValidationError):
        detail, field = _first_error(response.data)
        response.data = {"detail": detail, "code": "invalid", "field": field, "errors": response.data}
    elif isinstance(exc, ApiError):
        response.data = {"detail": str(exc.detail), "code": exc.code, **exc.extra}
    elif isinstance(response.data, dict) and "detail" in response.data:
        if isinstance(exc, Http404):
            code = "not_found"
        elif isinstance(exc, PermissionDenied):
            code = "permission_denied"
        else:
            code = getattr(exc, "default_code", "error")
        response.data["code"] = code
    return response
