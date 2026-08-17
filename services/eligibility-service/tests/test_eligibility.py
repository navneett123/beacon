import importlib.util
from pathlib import Path
import unittest


SERVICE_DIR = (
    Path(__file__)
    .resolve()
    .parents[1]
)

spec = importlib.util.spec_from_file_location(
    "eligibility_app",
    SERVICE_DIR / "app.py",
)

app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


PRODUCT = {
    "code": "PL-FLEX",
    "name": "Personal Loan Flex",

    "min_amount": 10000,
    "max_amount": 300000,

    "min_credit_score": 680,
    "min_monthly_income": 25000,

    "allowed_employment": [
        "SALARIED",
        "SELF_EMPLOYED",
    ],

    "tenure_months": [
        3,
        6,
        12,
        18,
        24,
    ],

    "processing_fee_percent": 1.5,
}


class EligibilityTests(unittest.TestCase):

    def test_valid_customer_is_eligible_with_all_checks_passing(self):
        result = app.evaluate_eligibility(
            {
                "product_code": "PL-FLEX",
                "requested_amount": 150000,
                "credit_score": 720,
                "employment_type": "salaried",
                "monthly_income": 55000,
            },
            PRODUCT,
        )

        self.assertTrue(
            result["eligible"]
        )

        self.assertEqual(
            result["product_code"],
            "PL-FLEX",
        )

        self.assertEqual(
            len(result["checks"]),
            4,
        )

        self.assertTrue(
            all(
                check["passed"]
                for check in result["checks"]
            )
        )


    def test_multiple_failures_keep_existing_reasons_and_add_checks(self):
        result = app.evaluate_eligibility(
            {
                "product_code": "PL-FLEX",
                "requested_amount": 500000,
                "credit_score": 620,
                "employment_type": "STUDENT",
                "monthly_income": 10000,
            },
            PRODUCT,
        )

        self.assertFalse(
            result["eligible"]
        )

        self.assertEqual(
            set(result["reasons"]),
            {
                "amount_out_of_range",
                "credit_score_below_threshold",
                "income_below_threshold",
                "employment_type_not_supported",
            },
        )

        checks = {
            check["rule"]: check
            for check in result["checks"]
        }

        self.assertEqual(
            set(checks),
            {
                "requested_amount",
                "credit_score",
                "monthly_income",
                "employment_type",
            },
        )

        self.assertFalse(
            checks["requested_amount"]["passed"]
        )

        self.assertEqual(
            checks["requested_amount"]["actual"],
            500000,
        )

        self.assertEqual(
            checks["requested_amount"]["minimum"],
            10000,
        )

        self.assertEqual(
            checks["requested_amount"]["maximum"],
            300000,
        )

        self.assertFalse(
            checks["credit_score"]["passed"]
        )

        self.assertEqual(
            checks["credit_score"]["actual"],
            620,
        )

        self.assertEqual(
            checks["credit_score"]["minimum"],
            680,
        )

        self.assertFalse(
            checks["monthly_income"]["passed"]
        )

        self.assertEqual(
            checks["monthly_income"]["actual"],
            10000,
        )

        self.assertEqual(
            checks["monthly_income"]["minimum"],
            25000,
        )

        self.assertFalse(
            checks["employment_type"]["passed"]
        )

        self.assertEqual(
            checks["employment_type"]["actual"],
            "STUDENT",
        )

        self.assertIn(
            "SALARIED",
            checks["employment_type"]["allowed"],
        )

        self.assertIn(
            "SELF_EMPLOYED",
            checks["employment_type"]["allowed"],
        )


    def test_mixed_result_explains_pass_and_fail_without_changing_reasons(self):
        result = app.evaluate_eligibility(
            {
                "product_code": "PL-FLEX",
                "requested_amount": 150000,
                "credit_score": 650,
                "employment_type": "SALARIED",
                "monthly_income": 50000,
            },
            PRODUCT,
        )

        self.assertFalse(
            result["eligible"]
        )

        # Existing response behaviour remains unchanged.
        self.assertEqual(
            result["reasons"],
            [
                "credit_score_below_threshold"
            ],
        )

        checks = {
            check["rule"]: check["passed"]
            for check in result["checks"]
        }

        self.assertEqual(
            checks,
            {
                "requested_amount": True,
                "credit_score": False,
                "monthly_income": True,
                "employment_type": True,
            },
        )


    def test_success_response_preserves_existing_business_fields(self):
        result = app.evaluate_eligibility(
            {
                "product_code": "PL-FLEX",
                "requested_amount": 150000,
                "credit_score": 720,
                "employment_type": "SALARIED",
                "monthly_income": 55000,
            },
            PRODUCT,
        )

        self.assertTrue(
            result["eligible"]
        )

        self.assertEqual(
            result["product_name"],
            "Personal Loan Flex",
        )

        self.assertEqual(
            result["approved_amount"],
            150000,
        )

        self.assertEqual(
            result["available_tenures_months"],
            [
                3,
                6,
                12,
                18,
                24,
            ],
        )

        self.assertEqual(
            result["processing_fee_percent"],
            1.5,
        )

        self.assertIn(
            "checks",
            result,
        )


    def test_missing_field_is_rejected_without_policy_evaluation(self):
        result = app.evaluate_eligibility(
            {
                "product_code": "PL-FLEX"
            },
            PRODUCT,
        )

        self.assertFalse(
            result["eligible"]
        )

        self.assertEqual(
            result["reason"],
            "missing_fields",
        )

        self.assertIn(
            "requested_amount",
            result["fields"],
        )

        self.assertNotIn(
            "checks",
            result,
        )


    def test_invalid_field_type_is_rejected_without_policy_evaluation(self):
        result = app.evaluate_eligibility(
            {
                "product_code": "PL-FLEX",
                "requested_amount": "not-a-number",
                "credit_score": 720,
                "employment_type": "SALARIED",
                "monthly_income": 55000,
            },
            PRODUCT,
        )

        self.assertFalse(
            result["eligible"]
        )

        self.assertEqual(
            result["reason"],
            "invalid_field_type",
        )

        self.assertNotIn(
            "checks",
            result,
        )


if __name__ == "__main__":
    unittest.main()