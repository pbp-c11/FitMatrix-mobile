from __future__ import annotations

from io import BytesIO
from typing import Any

import re

from django import forms
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.forms import PasswordChangeForm, UserCreationForm
from django.core.exceptions import ValidationError
from django.core.files.base import ContentFile
from django.utils.translation import gettext_lazy as _

try:  # pragma: no cover - fallback when Pillow is unavailable
    from PIL import Image, ImageOps
except ModuleNotFoundError:  # pragma: no cover - fallback when Pillow missing
    Image = None  # type: ignore[assignment]
    ImageOps = None  # type: ignore[assignment]

from places.models import Place

from .models import User

AVATAR_MAX_SIZE_MB = 2
AVATAR_LIMIT_BYTES = AVATAR_MAX_SIZE_MB * 1024 * 1024
_IMAGE_SIGNATURES = (
    (b"\x89PNG\r\n\x1a\n", "png"),
    (b"\xff\xd8\xff\xe0", "jpeg"),  # JPEG JFIF
    (b"\xff\xd8\xff\xe1", "jpeg"),  # JPEG EXIF
    (b"\xff\xd8\xff\xdb", "jpeg"),  # JPEG quantization tables
)


def _basic_image_type(file_obj: Any) -> str | None:
    header = file_obj.read(16)
    file_obj.seek(0)
    for signature, name in _IMAGE_SIGNATURES:
        if header.startswith(signature):
            return name
    if header.startswith(b"\xff\xd8"):
        return "jpeg"
    return None


class AvatarProcessingMixin:
    avatar_field_name = "avatar"

    def clean_avatar(self) -> Any:
        avatar = self.cleaned_data.get(self.avatar_field_name)
        if not avatar:
            return avatar
        if avatar.size > AVATAR_LIMIT_BYTES:
            raise ValidationError(
                _(f"Avatar must be smaller than {AVATAR_MAX_SIZE_MB}MB."),
            )
        if Image is not None:
            try:
                image = Image.open(avatar)
                image.verify()
            except Exception as exc:  # noqa: BLE001
                raise ValidationError(_("Upload a valid image (PNG/JPG).")) from exc
            finally:
                avatar.seek(0)
        else:
            kind = _basic_image_type(avatar)
            if kind not in {"png", "jpeg"}:
                raise ValidationError(_("Upload a valid image (PNG/JPG)."))
        return avatar

    def _process_avatar(self, instance: User) -> None:
        avatar = self.cleaned_data.get(self.avatar_field_name)
        if not avatar:
            return
        avatar.seek(0)
        if Image is None:
            instance.avatar = avatar
            return
        image = Image.open(avatar)
        image = ImageOps.exif_transpose(image)
        if image.mode not in ("RGB", "RGBA"):
            image = image.convert("RGB")
        image.thumbnail((512, 512))
        output = BytesIO()
        format_ = "PNG" if image.mode == "RGBA" else "JPEG"
        image.save(output, format=format_, quality=90)
        output.seek(0)
        name = avatar.name.rsplit(".", 1)[0]
        extension = "png" if format_ == "PNG" else "jpg"
        instance.avatar.save(
            f"{name}.{extension}",
            ContentFile(output.read()),
            save=False,
        )


class RegisterForm(AvatarProcessingMixin, UserCreationForm):
    avatar = forms.FileField(required=False)
    email = forms.EmailField()
    display_name = forms.CharField(max_length=100, required=False)

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("username", "email", "display_name", "password1", "password2", "avatar")

    def clean_email(self) -> str:
        email = self.cleaned_data.get("email", "").strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise ValidationError(_("Email address must be unique."))
        return email

    def save(self, commit: bool = True) -> User:
        user: User = super().save(commit=False)
        user.email = self.cleaned_data["email"].lower()
        user.display_name = self.cleaned_data.get("display_name") or ""
        if commit:
            user.save()
            self._process_avatar(user)
            user.save()
        else:
            self._process_avatar(user)
        return user


class AdminUserCreationForm(UserCreationForm):
    email = forms.EmailField()
    display_name = forms.CharField(max_length=100, required=False)

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ("username", "email", "display_name", "password1", "password2")

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        field_settings = {
            "username": {"autocomplete": "username"},
            "email": {"autocomplete": "email"},
            "display_name": {"autocomplete": "name"},
            "password1": {"autocomplete": "new-password"},
            "password2": {"autocomplete": "new-password"},
        }
        for name, attrs in field_settings.items():
            field = self.fields.get(name)
            if field is None:
                continue
            field.widget.attrs.setdefault("class", "input")
            for key, value in attrs.items():
                field.widget.attrs.setdefault(key, value)

    def clean_email(self) -> str:
        email = self.cleaned_data.get("email", "").strip().lower()
        if User.objects.filter(email__iexact=email).exists():
            raise ValidationError(_("Email address must be unique."))
        return email

    def save(self, commit: bool = True) -> User:
        user: User = super().save(commit=False)
        user.email = self.cleaned_data["email"].lower()
        user.display_name = self.cleaned_data.get("display_name") or ""
        user.role = User.Roles.ADMIN
        user.is_staff = True
        if commit:
            user.save()
        return user


class LoginForm(forms.Form):
    identifier = forms.CharField(label=_("Username or email"))
    password = forms.CharField(widget=forms.PasswordInput)

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        self.user_cache: User | None = None
        super().__init__(*args, **kwargs)

    def clean(self) -> dict[str, Any]:
        cleaned_data = super().clean()
        identifier = cleaned_data.get("identifier")
        password = cleaned_data.get("password")
        if identifier and password:
            UserModel = get_user_model()
            lookup = {"username": identifier}
            if "@" in identifier:
                lookup = {"email__iexact": identifier}
            try:
                user_obj = UserModel.objects.get(**lookup)
                username = user_obj.get_username()
            except UserModel.DoesNotExist:
                username = identifier
            self.user_cache = authenticate(username=username, password=password)
            if self.user_cache is None:
                raise ValidationError(_("Invalid credentials."))
        return cleaned_data

    def get_user(self) -> User | None:
        return self.user_cache


class ProfileForm(AvatarProcessingMixin, forms.ModelForm):
    avatar = forms.FileField(required=False)
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.fields["display_name"].widget.attrs.setdefault("class", "input")
        self.fields["email"].widget.attrs.setdefault("class", "input")
        self.fields["avatar"].widget.attrs.setdefault("class", "input")
        self.fields["avatar"].widget.attrs.setdefault("accept", "image/png,image/jpeg")
        self._update_aria_attributes()

    class Meta:
        model = User
        fields = ("display_name", "email", "avatar")

    def _update_aria_attributes(self) -> None:
        errors = getattr(self, "_errors", {}) or {}
        for name, field in self.fields.items():
            field.widget.attrs["aria-invalid"] = "true" if name in errors else "false"

    def full_clean(self) -> None:
        super().full_clean()
        self._update_aria_attributes()

    def clean_email(self) -> str:
        email = self.cleaned_data.get("email", "").strip()
        qs = User.objects.exclude(pk=self.instance.pk)
        if email and qs.filter(email__iexact=email).exists():
            raise ValidationError(_("Email address must be unique."))
        return email

    def save(self, commit: bool = True) -> User:
        user: User = super().save(commit=False)
        user.email = (self.cleaned_data.get("email") or "").lower()
        if commit:
            user.save()
            self._process_avatar(user)
            user.save()
        else:
            self._process_avatar(user)
        return user


class AccessiblePasswordChangeForm(PasswordChangeForm):
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        for name in self.fields:
            attrs = {"class": "input"}
            if name == "old_password":
                attrs["autocomplete"] = "current-password"
            else:
                attrs["autocomplete"] = "new-password"
            self.fields[name].widget.attrs.update(attrs)
        self._update_aria()

    def _update_aria(self) -> None:
        errors = getattr(self, "_errors", {}) or {}
        for name, field in self.fields.items():
            field.widget.attrs["aria-invalid"] = "true" if name in errors else "false"

    def full_clean(self) -> None:
        super().full_clean()
        self._update_aria()


class AdminPlaceForm(forms.ModelForm):
    amenities = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={"class": "input", "rows": 3}),
        help_text="Comma or newline separated list of amenities.",
    )
    gallery = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={"class": "input", "rows": 3}),
        help_text="Comma or newline separated list of gallery image URLs.",
    )

    class Meta:
        model = Place
        fields = (
            "name",
            "tagline",
            "summary",
            "tags",
            "address",
            "city",
            "latitude",
            "longitude",
            "facility_type",
            "amenities",
            "highlight_score",
            "accent_color",
            "hero_image",
            "gallery",
            "is_free",
            "price",
            "is_active",
        )
        widgets = {
            "name": forms.TextInput(attrs={"class": "input"}),
            "tagline": forms.TextInput(attrs={"class": "input"}),
            "summary": forms.Textarea(attrs={"class": "input", "rows": 4}),
            "tags": forms.TextInput(attrs={"class": "input"}),
            "address": forms.TextInput(attrs={"class": "input"}),
            "city": forms.TextInput(attrs={"class": "input"}),
            "latitude": forms.NumberInput(
                attrs={
                    "class": "input",
                    "step": "0.000001",
                    "placeholder": "-6.175392",
                }
            ),
            "longitude": forms.NumberInput(
                attrs={
                    "class": "input",
                    "step": "0.000001",
                    "placeholder": "106.827153",
                }
            ),
            "facility_type": forms.Select(attrs={"class": "input"}),
            "highlight_score": forms.NumberInput(attrs={"class": "input"}),
            "accent_color": forms.TextInput(attrs={"class": "input", "placeholder": "#03B863"}),
            "hero_image": forms.TextInput(attrs={"class": "input"}),
            "is_free": forms.CheckboxInput(attrs={"class": "input-toggle"}),
            "price": forms.NumberInput(attrs={"class": "input", "step": "0.01", "min": "0"}),
            "is_active": forms.CheckboxInput(attrs={"class": "input-toggle"}),
        }

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            self.initial.setdefault("amenities", self._join_list(self.instance.amenities_list()))
            self.initial.setdefault("gallery", self._join_list(self.instance.gallery_list()))

    def _join_list(self, values: list[str]) -> str:
        return "\n".join(values)

    def _split_value(self, value: str) -> list[str]:
        if not value:
            return []
        parts = re.split(r"[\n,]+", value)
        return [item.strip() for item in parts if item.strip()]

    def clean_amenities(self) -> list[str]:
        amenities = self.cleaned_data.get("amenities", "")
        return self._split_value(amenities)

    def clean_gallery(self) -> list[str]:
        gallery = self.cleaned_data.get("gallery", "")
        return self._split_value(gallery)
