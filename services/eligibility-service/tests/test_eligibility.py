import importlib.util
from pathlib import Path
import unittest

SERVICE_DIR = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("eligibility_app", SERVICE_DIR / "app.py")
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)

PRODUCT = {
    "code": "PL-FLEX",
    "name": "Personal Loan Flex",
    "min_amount": 10000,
    "max_amount": 300000,
    "min_credit_score": 680,
    "min_monthly_income": 25000,
    "allowed_employment": ["SALARIED", "SELF_EMPLOYED"],
    "tenure_months": [3, 6, 12, 18, 24],
    "processing_fee_percent": 1.5,
}


class EligibilityTests(unittest.TestCase):
    def test_valid_customer_is_eligible(self):
        result = app.evaluate_eligibility({
            "product_code": "PL-FLEX",
            "requested_amount": 150000,
            "credit_score": 720,
            "employment_type": "salaried",
            "monthly_income": 55000,
        }, PRODUCT)
        self.assertTrue(result["eligible"])
        self.assertEqual(result["product_code"], "PL-FLEX")

    def test_multiple_failures_are_returned(self):
        result = app.evaluate_eligibility({
            "product_code": "PL-FLEX",
            "requested_amount": 500000,
            "credit_score": 620,
            "employment_type": "STUDENT",
            "monthly_income": 10000,
        }, PRODUCT)
        self.assertFalse(result["eligible"])
        self.assertEqual(set(result["reasons"]), {
            "amount_out_of_range",
            "credit_score_below_threshold",
            "income_below_threshold",
            "employment_type_not_supported",
        })

    def test_missing_field_is_rejected(self):
        result = app.evaluate_eligibility({"product_code": "PL-FLEX"}, PRODUCT)
        self.assertFalse(result["eligible"])
        self.assertEqual(result["reason"], "missing_fields")


if __name__ == "__main__":
    unittest.main()
