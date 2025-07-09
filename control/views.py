from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth import logout as auth_logout
from django.urls import reverse
import requests
from .forms import ControlForm, RegisterForm
from django.contrib.auth.models import User

from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent.parent

BACKEND_API_URL = 'http://localhost:8000/api'  # Adjust as needed


def control(request):
    if request.method == 'POST':
        form = ControlForm(request.POST)
        if form.is_valid():
            if 'logout' in request.POST:
                auth_logout(request)
                return redirect(reverse('login'))
            elif 'go' in request.POST:
                angle = form.cleaned_data['angle']
                try:
                    r = requests.post(f'{BACKEND_API_URL}/goto_angle', json={'angle': angle})
                    if r.ok:
                        messages.info(request, f'Moving to angle {angle}°')
                    else:
                        messages.error(request, f'Failed to move: {r.text}')
                except Exception as e:
                    messages.error(request, f'Error: {e}')
                return redirect('control')
            elif 'set_zero' in request.POST:
                zero = form.cleaned_data['zero']
                try:
                    r = requests.post(f'{BACKEND_API_URL}/set_zero_position', json=zero)
                    if r.ok:
                        messages.success(request, f'Zero position set to {zero}')
                    else:
                        messages.error(request, f'Failed to set zero: {r.text}')
                except Exception as e:
                    messages.error(request, f'Error: {e}')
                return redirect('control')
    else:
        form = ControlForm()
    # Use the correct template based on user type
    template_name = 'control/control.html'
    if request.user.is_authenticated and request.user.is_staff:
        # This will resolve to control_admin_v1 first due to INSTALLED_APPS order
        template_name = 'control/control.html'
    else:
        # This will resolve to control_public_v1 first due to INSTALLED_APPS order
        template_name = 'control/control.html'
    return render(request, template_name, {'form': form})


def register(request):
    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Account created successfully. You can now log in.')
            return redirect('login')
    else:
        form = RegisterForm()
    return render(request, 'control/register.html', {'form': form})
