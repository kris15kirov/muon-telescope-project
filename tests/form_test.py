from django.test import TestCase
from control.forms import ControlForm


class ControlFormTests(TestCase):
    def test_invalid_angle(self):
        form = ControlForm(data={"angle": -100, "zero": 0})
        self.assertFalse(form.is_valid())

    def test_valid_angle(self):
        form = ControlForm(data={"angle": 45, "zero": 0})
        self.assertTrue(form.is_valid())
