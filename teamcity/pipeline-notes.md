# Beacon TeamCity build configuration

Use one Command Line build step from the repository root:

```bash
./teamcity/build.sh "1.0.%build.number%"
```

Do not deploy Kubernetes from TeamCity. TeamCity owns tests, Docker builds, immutable image tags, registry push, and local Kustomize render validation. Octopus owns DEV/PROD deployment and promotion.
