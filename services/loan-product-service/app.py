import json
import os
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

PORT = int(os.getenv("PORT", "8080"))
APP_VERSION = os.getenv("APP_VERSION", "dev")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
DATA_FILE = Path(__file__).with_name("products.json")


def load_products():
    with DATA_FILE.open(encoding="utf-8") as handle:
        products = json.load(handle)
    return {item["code"]: item for item in products}


PRODUCTS = load_products()


class Handler(BaseHTTPRequestHandler):
    server_version = "BeaconLoanProduct/1.0"

    def log_message(self, fmt, *args):
        print(f"loan-product-service {self.address_string()} - {fmt % args}", flush=True)

    def send_json(self, status, payload):
        body = json.dumps(payload, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            return self.send_json(HTTPStatus.OK, {"status": "healthy"})
        if path == "/version":
            return self.send_json(HTTPStatus.OK, {
                "service": "loan-product-service",
                "version": APP_VERSION,
                "environment": ENVIRONMENT,
            })
        if path == "/products":
            return self.send_json(HTTPStatus.OK, {"products": list(PRODUCTS.values())})
        if path.startswith("/products/"):
            code = path.rsplit("/", 1)[-1].upper()
            product = PRODUCTS.get(code)
            if product is None:
                return self.send_json(HTTPStatus.NOT_FOUND, {"error": "product_not_found", "code": code})
            return self.send_json(HTTPStatus.OK, product)
        return self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found"})


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"loan-product-service listening on {PORT}", flush=True)
    server.serve_forever()
