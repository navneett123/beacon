import importlib.util
import json
from pathlib import Path
import unittest

SERVICE_DIR = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("loan_product_app", SERVICE_DIR / "app.py")
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


class ProductTests(unittest.TestCase):
    def test_products_load_and_codes_are_unique(self):
        products = app.load_products()
        self.assertIn("PL-FLEX", products)
        self.assertIn("BNPL-LITE", products)
        self.assertEqual(len(products), 2)

    def test_product_bounds_are_valid(self):
        for product in app.load_products().values():
            self.assertLess(product["min_amount"], product["max_amount"])
            self.assertGreaterEqual(product["min_credit_score"], 300)
            self.assertLessEqual(product["min_credit_score"], 900)
            self.assertGreater(product["processing_fee_percent"], 0)


if __name__ == "__main__":
    unittest.main()
