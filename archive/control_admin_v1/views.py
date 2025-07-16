from django.shortcuts import render

# Create your views here.


def control(request):
    """Admin control view."""
    return render(request, "control/control.html")
