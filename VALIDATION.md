# Beacon pre-generation validation

Validated before handoff:

- 5/5 Python unit tests passed.
- Both Python applications passed byte-code compilation.
- Both services were started locally and an end-to-end eligibility request passed.
- All generated Bash scripts passed `bash -n` syntax validation.
- All Kubernetes/Kustomize YAML parsed successfully and overlay semantics were checked.
- DEV and PROD overlays both reference the same `#{Octopus.Release.Number}` for both image tags and `APP_VERSION`.
- Version references in Dockerfiles and `versions.lock` were checked for consistency.
- No Helm/chart or obsolete manifest-package path remains in the project.

Runtime-only checks intentionally happen on the target Beacon VM because this handoff environment does not provide Docker/k3d. The generated gates stop on first failure and validate the actual Docker engine, pinned k3d/Kubernetes/kubectl combination, local registry, image pull, TeamCity startup, Octopus/SQL startup, Kubernetes connectivity, DEV rollout and smoke tests before the real release flow is used.
