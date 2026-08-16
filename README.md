# Beacon — Loan Product Configuration & Eligibility Release Platform

Beacon is a deliberately small, production-shaped fintech CI/CD lab.

## Application

Two Python microservices, with no third-party Python packages:

- `loan-product-service` — exposes loan product rules/configuration.
- `eligibility-service` — serves the responsive Beacon web UI, evaluates applications, and calls `loan-product-service` over Kubernetes service DNS.

The UI is deliberately embedded in `eligibility-service`, so the lab keeps exactly two application containers and adds no Node/React build, NGINX layer, extra Kubernetes Service, or extra deployment target.

## Web UI

After deploying an environment, port-forward the eligibility service:

```bash
kubectl -n beacon-dev port-forward service/eligibility-service 18080:8080
```

Then open `http://127.0.0.1:18080/` in a browser. The UI loads the live product catalog through the eligibility service and submits decisions to the existing `/eligibility` API.

## Delivery model

Git -> TeamCity -> test/build two immutable Docker images -> local registry -> Octopus Deploy -> Kustomize DEV overlay -> smoke test -> manual promotion -> same release to PROD -> smoke test / rollback.

## Deliberate scope cuts

No Helm, application database, Kafka/RabbitMQ, Redis, ingress, service mesh, GitOps controller, separate frontend runtime, or observability stack.

## Kubernetes structure

- one single-node k3d cluster
- namespaces: `beacon-dev`, `beacon-prod`
- Kustomize base plus DEV/PROD overlays
- both overlays use `#{Octopus.Release.Number}` as the immutable image tag

## Important release invariant

A TeamCity build produces one Beacon version, e.g. `1.0.2`. Both images are tagged `1.0.2`. The Octopus release must also be `1.0.2`. PROD receives the same Octopus release that passed DEV; there is no rebuild.

See `DEPLOYMENT.md` and `octopus/deployment-notes.md`.
