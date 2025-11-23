from __future__ import annotations

from django import forms

from django.utils import timezone

from .models import Booking, SessionSlot, Trainer


class SessionSlotForm(forms.ModelForm):
    class Meta:
        model = SessionSlot
        fields = ("trainer", "place", "start", "end", "capacity", "is_active")
        widgets = {
            "start": forms.DateTimeInput(attrs={"type": "datetime-local"}),
            "end": forms.DateTimeInput(attrs={"type": "datetime-local"}),
        }

    def clean(self):
        cleaned = super().clean()
        start = cleaned.get("start")
        end = cleaned.get("end")
        if start and end and end <= start:
            self.add_error("end", "End time must be after start time.")
        return cleaned


class TrainerForm(forms.ModelForm):
    class Meta:
        model = Trainer
        fields = (
            "name",
            "specialties",
            "bio",
            "price_per_session",
            "likes",
            "calendly_url",
            "rating_avg",
            "is_active",
        )
        widgets = {
            "name": forms.TextInput(attrs={"class": "input"}),
            "specialties": forms.TextInput(attrs={"class": "input"}),
            "bio": forms.Textarea(attrs={"class": "input", "rows": 4}),
            "price_per_session": forms.NumberInput(
                attrs={"class": "input", "min": "0", "step": "0.01"}
            ),
            "likes": forms.NumberInput(attrs={"class": "input", "min": "0"}),
            "calendly_url": forms.URLInput(attrs={"class": "input"}),
            "rating_avg": forms.NumberInput(
                attrs={"class": "input", "min": "0", "max": "5", "step": "0.1"}
            ),
            "is_active": forms.CheckboxInput(attrs={"class": "input-toggle"}),
        }

class BookingRequestForm(forms.Form):
    slot = forms.ModelChoiceField(queryset=SessionSlot.objects.none(), widget=forms.HiddenInput)

    def __init__(self, user, *args, **kwargs):
        self.user = user
        super().__init__(*args, **kwargs)
        self.fields["slot"].queryset = SessionSlot.objects.select_related("trainer", "place").filter(is_active=True)

    def clean_slot(self):
        slot: SessionSlot = self.cleaned_data["slot"]
        if slot.start < timezone.now():
            raise forms.ValidationError("This slot has already started.")
        if slot.seats_left() <= 0:
            raise forms.ValidationError("This slot is fully booked.")
        if (
            Booking.objects.filter(user=self.user, slot=slot, status=Booking.Status.BOOKED)
            .exists()
        ):
            raise forms.ValidationError("You have already booked this slot.")
        return slot


class BookingRescheduleForm(forms.Form):
    new_slot = forms.ModelChoiceField(queryset=SessionSlot.objects.none(), label="New session")

    def __init__(self, booking: Booking, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.booking = booking
        trainer = booking.slot.trainer
        self.fields["new_slot"].queryset = (
            SessionSlot.objects.filter(trainer=trainer, is_active=True, start__gte=timezone.now())
            .exclude(pk=booking.slot_id)
            .select_related("place", "trainer")
        )
        self.fields["new_slot"].widget.attrs.update({"class": "matrix-input"})

    def clean_new_slot(self):
        slot: SessionSlot = self.cleaned_data["new_slot"]
        if slot.seats_left() <= 0:
            raise forms.ValidationError("Selected slot is already full.")
        if (
            Booking.objects.filter(user=self.booking.user, slot=slot, status=Booking.Status.BOOKED)
            .exclude(pk=self.booking.pk)
            .exists()
        ):
            raise forms.ValidationError("You already have this slot booked.")
        return slot
