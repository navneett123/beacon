from pathlib import Path
import unittest


SERVICE_DIR = (
    Path(__file__)
    .resolve()
    .parents[1]
)

UI_FILE = (
    SERVICE_DIR
    / "ui.html"
)

DOCKERFILE = (
    SERVICE_DIR
    / "Dockerfile"
)


class UiIntegrationTests(unittest.TestCase):

    def test_ui_asset_exists_and_targets_existing_api(self):
        html = UI_FILE.read_text(
            encoding="utf-8"
        )

        # Existing Beacon UI identity
        self.assertIn(
            "Beacon · Loan Eligibility",
            html,
        )

        # Existing API integrations
        self.assertIn(
            "'/eligibility'",
            html,
        )

        self.assertIn(
            "'/products'",
            html,
        )

        self.assertIn(
            "'/version'",
            html,
        )

        # Feature 1:
        # Explainable Eligibility UI
        self.assertIn(
            "Policy checks",
            html,
        )

        self.assertIn(
            'id="policySection"',
            html,
        )

        self.assertIn(
            'id="policySummary"',
            html,
        )

        self.assertIn(
            'id="policyChecks"',
            html,
        )

        self.assertIn(
            "describeCheck",
            html,
        )

        self.assertIn(
            "renderPolicyChecks",
            html,
        )

        self.assertIn(
            "renderPolicyChecks(",
            html,
        )

        self.assertIn(
            "data.checks",
            html,
        )

        # Visible PASS / FAIL rendering
        self.assertIn(
            "'Pass'",
            html,
        )

        self.assertIn(
            "'Fail'",
            html,
        )

        # Individual explainable rules
        self.assertIn(
            "Requested amount",
            html,
        )

        self.assertIn(
            "Credit score",
            html,
        )

        self.assertIn(
            "Monthly income",
            html,
        )

        self.assertIn(
            "Employment type",
            html,
        )

        # Existing responsive behaviour preserved
        self.assertIn(
            "@media (max-width: 680px)",
            html,
        )

        self.assertIn(
            ".policy-check-status",
            html,
        )


    def test_ui_is_copied_into_container_image(self):
        dockerfile = DOCKERFILE.read_text(
            encoding="utf-8"
        )

        # Existing image packaging must remain intact.
        self.assertIn(
            "app.py ui.html",
            dockerfile,
        )


if __name__ == "__main__":
    unittest.main()