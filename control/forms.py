from django import forms
from django.contrib.auth.models import User

class ControlForm(forms.Form):
    angle = forms.IntegerField(
        label="Angle",
        min_value=-75,
        max_value=75,
        widget=forms.NumberInput(attrs={
            'type': 'range',
            'class': 'form-range',
            'min': -75,
            'max': 75,
        })
    )
    zero = forms.IntegerField(
        label="Zero Position",
        widget=forms.NumberInput(attrs={
            'class': 'form-control',
            'placeholder': 'Zero Position',
        })
    )

class RegisterForm(forms.ModelForm):
    password1 = forms.CharField(label='Password', widget=forms.PasswordInput)
    password2 = forms.CharField(label='Confirm Password', widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = ('username',)

    def clean_password2(self):
        password1 = self.cleaned_data.get('password1')
        password2 = self.cleaned_data.get('password2')
        if password1 and password2 and password1 != password2:
            raise forms.ValidationError("Passwords don't match")
        return password2

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data['password1'])
        if commit:
            user.save()
        return user

# Note: Submit buttons (Go to Angle, Set Zero, Logout) should be rendered in the template using <button> elements with the correct names and Bootstrap classes. 