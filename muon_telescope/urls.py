"""
URL configuration for muon_telescope project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home, name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView
from django.contrib.auth import views as auth_views
from control import views as control_views
from django.conf import settings
from django.views.static import serve

urlpatterns = [
    path("", RedirectView.as_view(url="login/", permanent=False)),
    path("admin/", admin.site.urls),
    path(
        "login/",
        control_views.MyLoginView.as_view(template_name="login.html"),
        name="login",
    ),
    path("logout/", auth_views.LogoutView.as_view(next_page="login"), name="logout"),
    path("control/", control_views.control, name="control"),
    path("register/", control_views.register, name="register"),
    # path("control/", include("control.urls")), # archived
    # path("control-admin/", include("control_admin_v1.urls")),  # archived
    # path("control-public/", include("control_public_v1.urls")),  # archived
    # API Endpoints at root level
    path("api/motor/move/", control_views.api_move_motor, name="api_move_motor"),
    path("api/motor/stop/", control_views.api_stop_motor, name="api_stop_motor"),
    path(
        "api/motor/reset/", control_views.api_reset_position, name="api_reset_position"
    ),
    path("api/status/", control_views.api_motor_status, name="api_motor_status"),
    path("api/logs/", control_views.api_movement_logs, name="api_movement_logs"),
    path("api/goto_angle/", control_views.api_goto_angle, name="api_goto_angle"),
    path(
        "api/set_zero_position/",
        control_views.api_set_zero_position,
        name="api_set_zero_position",
    ),
    path(
        "api/enable_stepper/",
        control_views.api_enable_stepper,
        name="api_enable_stepper",
    ),
    path(
        "api/disable_stepper/",
        control_views.api_disable_stepper,
        name="api_disable_stepper",
    ),
    path(
        "api/set_direction/", control_views.api_set_direction, name="api_set_direction"
    ),
    path("api/health/", control_views.api_health, name="api_health"),
    path("api/shutdown/", control_views.api_shutdown, name="api_shutdown"),
    path(
        "api/set_step_period/",
        control_views.api_set_step_period,
        name="api_set_step_period",
    ),
    path("api/do_steps/", control_views.api_do_steps, name="api_do_steps"),
#    path("api/do_steps_pwm/", control_views.api_do_steps_pwm, name="api_do_steps_pwm"),
    path("api/quit_motor/", control_views.api_quit_motor, name="api_quit_motor"),
    path("api/pause_motor/", control_views.api_pause_motor, name="api_pause_motor"),
    path("api/resume_motor/", control_views.api_resume_motor, name="api_resume_motor"),
]

# Serve favicon.ico at the root
urlpatterns += [
    path(
        "favicon.ico",
        serve,
        {"path": "favicon.ico", "document_root": settings.STATICFILES_DIRS[0]},
    ),
]
