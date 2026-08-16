import json
import os
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

PORT = int(os.getenv("PORT", "8080"))
APP_VERSION = os.getenv("APP_VERSION", "dev")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
LOAN_PRODUCT_URL = os.getenv("LOAN_PRODUCT_URL", "http://loan-product-service:8080").rstrip("/")
UPSTREAM_TIMEOUT_SECONDS = float(os.getenv("UPSTREAM_TIMEOUT_SECONDS", "2.0"))


REQUIRED_FIELDS = {
    "product_code",
    "requested_amount",
    "credit_score",
    "employment_type",
    "monthly_income",
}


def fetch_product(product_code):
    url = f"{LOAN_PRODUCT_URL}/products/{quote(str(product_code).upper())}"
    request = Request(url, headers={"Accept": "application/json"})
    with urlopen(request, timeout=UPSTREAM_TIMEOUT_SECONDS) as response:
        return json.loads(response.read().decode())


def evaluate_eligibility(payload, product):
    missing = sorted(REQUIRED_FIELDS - payload.keys())
    if missing:
        return {"eligible": False, "reason": "missing_fields", "fields": missing}

    try:
        amount = float(payload["requested_amount"])
        score = int(payload["credit_score"])
        income = float(payload["monthly_income"])
        employment = str(payload["employment_type"]).upper()
    except (TypeError, ValueError):
        return {"eligible": False, "reason": "invalid_field_type"}

    reasons = []
    if not product["min_amount"] <= amount <= product["max_amount"]:
        reasons.append("amount_out_of_range")
    if score < product["min_credit_score"]:
        reasons.append("credit_score_below_threshold")
    if income < product["min_monthly_income"]:
        reasons.append("income_below_threshold")
    if employment not in product["allowed_employment"]:
        reasons.append("employment_type_not_supported")

    if reasons:
        return {
            "eligible": False,
            "product_code": product["code"],
            "reasons": reasons,
        }

    return {
        "eligible": True,
        "product_code": product["code"],
        "product_name": product["name"],
        "approved_amount": amount,
        "available_tenures_months": product["tenure_months"],
        "processing_fee_percent": product["processing_fee_percent"],
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "BeaconEligibility/1.0"

    def log_message(self, fmt, *args):
        print(f"eligibility-service {self.address_string()} - {fmt % args}", flush=True)

    def send_json(self, status, payload):
        body = json.dumps(payload, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def read_json(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            raise ValueError("invalid_content_length")
        if length <= 0 or length > 1024 * 64:
            raise ValueError("invalid_body_size")
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode())
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ValueError("invalid_json") from exc
        if not isinstance(payload, dict):
            raise ValueError("body_must_be_object")
        return payload

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            return self.send_json(HTTPStatus.OK, {"status": "healthy"})
        if path == "/version":
            return self.send_json(HTTPStatus.OK, {
                "service": "eligibility-service",
                "version": APP_VERSION,
                "environment": ENVIRONMENT,
            })
        return self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found"})

    def do_POST(self):
        if urlparse(self.path).path != "/eligibility":
            return self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found"})
        try:
            payload = self.read_json()
        except ValueError as exc:
            return self.send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})

        product_code = payload.get("product_code")
        if not product_code:
            return self.send_json(HTTPStatus.BAD_REQUEST, {"error": "product_code_required"})

        try:
            product = fetch_product(product_code)
        except HTTPError as exc:
            if exc.code == HTTPStatus.NOT_FOUND:
                return self.send_json(HTTPStatus.BAD_REQUEST, {"error": "unknown_product"})
            return self.send_json(HTTPStatus.BAD_GATEWAY, {"error": "loan_product_service_http_error"})
        except (URLError, TimeoutError, json.JSONDecodeError):
            return self.send_json(HTTPStatus.SERVICE_UNAVAILABLE, {"error": "loan_product_service_unavailable"})

        result = evaluate_eligibility(payload, product)
        status = HTTPStatus.OK if result.get("eligible") else HTTPStatus.UNPROCESSABLE_ENTITY
        return self.send_json(status, result)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"eligibility-service listening on {PORT}; upstream={LOAN_PRODUCT_URL}", flush=True)
    server.serve_forever()
