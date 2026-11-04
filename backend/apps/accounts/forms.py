from django import forms
from django.contrib.admin.forms import AdminAuthenticationForm


class StaffLoginForm(AdminAuthenticationForm):
    """Django admin login that accepts an email address or a phone number."""

    username = forms.CharField(
        label="Email or phone", max_length=254, widget=forms.TextInput(attrs={"autofocus": True})
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Django copies the phone field's length (11) onto this input, which cut emails short in the browser.
        field = self.fields["username"]
        field.max_length = 254
        field.widget.attrs["maxlength"] = "254"
