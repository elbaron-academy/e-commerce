from django import forms
from django.contrib.admin.forms import AdminAuthenticationForm


class StaffLoginForm(AdminAuthenticationForm):
    """Django admin login that accepts an email address or a phone number."""

    username = forms.CharField(
        label="Email or phone", max_length=254, widget=forms.TextInput(attrs={"autofocus": True})
    )
