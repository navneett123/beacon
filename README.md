# Beacon — Loan Product Configuration & Eligibility Release Platform

Beacon is a deliberately small, production-shaped fintech CI/CD lab.

## Application

Two Python microservices, with no third-party Python packages:

- `loan-product-service` — exposes loan product rules/configuration.
- `eligibility-service` — evaluates an application and calls `loan-product-service` over Kubernetes service DNS.

## Delivery model

Git -> TeamCity -> test/build two immutable Docker images -> local registry -> Octopus Deploy -> Kustomize DEV overlay -> smoke test -> manual approval -> same release to PROD -> smoke test / rollback.

## Deliberate scope cuts

No Helm, application database, Kafka/RabbitMQ, Redis, ingress, service mesh, GitOps controller, or observability stack.

## Kubernetes structure

- one single-node k3d cluster
- namespaces: `beacon-dev`, `beacon-prod`
- Kustomize base plus DEV/PROD overlays
- both overlays use `#{Octopus.Release.Number}` as the immutable image tag

## Important release invariant

A TeamCity build produces one Beacon version, e.g. `1.0.27`. Both images are tagged `1.0.27`. The Octopus release must also be `1.0.27`. PROD receives the same Octopus release that passed DEV; there is no rebuild.

See `DEPLOYMENT.md` and `octopus/deployment-notes.md`.
