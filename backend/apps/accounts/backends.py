from django.contrib.auth.backends import ModelBackend

from apps.core.text import normalize_phone

from .models import User


class PhoneOrEmailBackend(ModelBackend):
    """Password login with a phone number, or with an email address for staff accounts."""

    def authenticate(self, request, username=None, password=None, **kwargs):
        login = (username or kwargs.get("phone") or kwargs.get("email") or "").strip()
        if not login or password is None:
            return None
        if "@" in login:
            user = User.objects.filter(email__iexact=login, is_staff=True).order_by("pk").first()
        else:
            user = User.objects.filter(phone=normalize_phone(login)).first()
        if user is None:
            User().set_password(password)  # same timing whether or not the account exists
            return None
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
