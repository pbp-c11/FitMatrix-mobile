from django import forms
from .models import Review

class ReviewForm(forms.ModelForm):
    RATING_CHOICES = [(i, str(i)) for i in range(1, 6)]  # 1..5

    rating = forms.ChoiceField(choices=RATING_CHOICES, widget=forms.Select(attrs={
        "class": "matrix-input",  # tailwind kamu bakal override lewat css
    }))
    body = forms.CharField(required=False, widget=forms.Textarea(attrs={
        "rows": 3,
        "class": "matrix-input",
        "placeholder": "Share your experience…",
    }))

    class Meta:
        model = Review
        fields = ["rating", "body"]
