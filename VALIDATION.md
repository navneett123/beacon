# Beacon validation

Validated for the UI-enabled handoff:

- 7/7 Python/unit integration checks pass (loan-product rules, eligibility rules, and UI packaging/wiring).
- Both Python applications pass byte-code compilation.
- The two services start locally and the end-to-end product catalog + eligibility request passes.
- The root path `/` serves the responsive Beacon Loan Eligibility UI.
- The deployment smoke test now verifies health, web UI availability, release version, and the business eligibility flow.
- All generated Bash scripts pass `bash -n` syntax validation.
- DEV and PROD Kustomize overlays remain unchanged and continue to reference the same `#{Octopus.Release.Number}` for both image tags and `APP_VERSION`.
- No Helm/chart, Node/React runtime, NGINX frontend, extra Kubernetes Service, or third application container was introduced.

Runtime checks still happen on the Beacon VM because the deployment path depends on its Docker/k3d/TeamCity/Octopus stack. The existing gates stop on first failure and validate the actual registry, Kubernetes rollout, UI endpoint, release version, and application behavior.
