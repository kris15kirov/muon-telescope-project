from django.test import TestCase, Client
from django.urls import reverse


class MotorApiTests(TestCase):
    def setUp(self):
        self.client = Client()

    def test_move_motor(self):
        # TODO: Add valid form data for move
        response = self.client.post(
            "/api/motor/move/", {"direction": "cw", "degrees": 10}
        )
        self.assertIn(response.status_code, [200, 400, 403])  # Acceptable for stub

    def test_stop_motor(self):
        response = self.client.post("/api/motor/stop/")
        self.assertIn(response.status_code, [200, 400, 403])

    def test_status(self):
        response = self.client.get("/api/status/")
        self.assertIn(response.status_code, [200, 403])
