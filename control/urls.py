from django.urls import path
from django.contrib.auth import views as auth_views
from . import views

import threading
import time

urlpatterns = [
    path("", views.control, name="control"),
    path("logout/", auth_views.LogoutView.as_view(next_page="login"), name="logout"),
    path("register/", views.register, name="register"),
    # API Endpoints
    path("api/motor/move/", views.api_move_motor, name="api_move_motor"),
    path("api/motor/stop/", views.api_stop_motor, name="api_stop_motor"),
    path("api/motor/reset/", views.api_reset_position, name="api_reset_position"),
    path("api/status/", views.api_motor_status, name="api_motor_status"),
    path("api/logs/", views.api_movement_logs, name="api_movement_logs"),
    path("api/goto_angle/", views.api_goto_angle, name="api_goto_angle"),
    path(
        "api/set_zero_position/",
        views.api_set_zero_position,
        name="api_set_zero_position",
    ),
    path("api/enable_stepper/", views.api_enable_stepper, name="api_enable_stepper"),
    path("api/disable_stepper/", views.api_disable_stepper, name="api_disable_stepper"),
    path("api/set_direction/", views.api_set_direction, name="api_set_direction"),
    path("api/health/", views.api_health, name="api_health"),
    path("api/quit_motor/", views.api_quit_motor, name="api_quit_motor"),
    path("api/pause_motor/", views.api_pause_motor, name="api_pause_motor"),
    path("api/resume_motor/", views.api_resume_motor, name="api_resume_motor"),
    path("api/motor_busy/", views.api_motor_busy, name="api_motor_busy"),
]
