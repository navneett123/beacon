from pathlib import Path
import unittest

SERVICE_DIR = Path(__file__).resolve().parents[1]
UI_FILE = SERVICE_DIR / "ui.html"
DOCKERFILE = SERVICE_DIR / "Dockerfile"


class UiIntegrationTests(unittest.TestCase):
    def test_ui_asset_exists_and_targets_existing_api(self):
        html = UI_FILE.read_text(encoding="utf-8")
        self.assertIn("Beacon · Loan Eligibility", html)
        self.assertIn("fetch('/eligibility'", html)
        self.assertIn("fetch('/products'", html)
        self.assertIn("fetch('/version'", html)
        self.assertIn("@media (max-width: 680px)", html)

    def test_ui_is_copied_into_container_image(self):
        dockerfile = DOCKERFILE.read_text(encoding="utf-8")
        self.assertIn("app.py ui.html", dockerfile)


if __name__ == "__main__":
    unittest.main()
