# Beacon deployment gates

Do these in order. Stop immediately if a gate fails; do not continue and stack failures.

1. `./scripts/00-preflight.sh`
2. `./scripts/01-install-base.sh`; log out/in once so Docker group membership is active.
3. `./scripts/02-bootstrap-k3d.sh`
4. `./scripts/03-build-test-images.sh 0.1.0-preflight`
5. `./scripts/05-render-verify.sh 0.1.0-preflight`
6. `./scripts/08-dev-preflight-deploy.sh 0.1.0-preflight` — renders the Octopus variables locally, deploys DEV once, waits for both rollouts, and runs the smoke test.
7. Install TeamCity using `./teamcity/install-teamcity.sh`; complete first-run UI and authorize the bundled agent.
8. Run one TeamCity build with `teamcity/build.sh`. It must test, build, push both images, and validate both Kustomize overlays.
9. Run `./octopus/prepare-env.sh`, then `./octopus/start-octopus.sh`. If automatic free licensing is unavailable, add your Base64 license to `octopus/.env` and restart.
10. Configure Octopus Kubernetes targets using `./scripts/07-octopus-credentials.sh`, URL `https://host.docker.internal:6550`, namespaces `beacon-dev` and `beacon-prod`.
11. Configure one Octopus project `Beacon`, lifecycle DEV -> manual approval -> PROD, and one **Deploy with Kustomize** step sourced from this Git repository. See `octopus/deployment-notes.md`.
12. TeamCity build `N` produces image version `1.0.N`. Create Octopus release with the exact same version `1.0.N`.
13. Deploy that release to DEV and run `./scripts/06-smoke-test.sh beacon-dev 1.0.N`.
14. Approve the exact same release for PROD; deploy and run `./scripts/06-smoke-test.sh beacon-prod 1.0.N`.
15. Validate rollback by redeploying the preceding Octopus release.
16. Cleanup with `./scripts/99-cleanup.sh all`.
