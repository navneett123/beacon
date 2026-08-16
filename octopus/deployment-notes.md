# Beacon Octopus deployment wiring

Use one Octopus project named **Beacon**.

## Environments and lifecycle

- DEV
- PROD
- Lifecycle order: DEV -> manual promotion -> PROD

## Kubernetes targets

Use the Kubernetes API target type.

- Cluster URL from the Octopus container: `https://host.docker.internal:6550`
- DEV target namespace: `beacon-dev`
- PROD target namespace: `beacon-prod`
- Target role: `beacon-k8s`
- Use the service-account token and CA printed by `scripts/07-octopus-credentials.sh`.

## Deploy with Kustomize step

Configure one **Deploy with Kustomize** step targeting role `beacon-k8s`.

Source the Beacon Git repository containing this project. The overlay path differs by environment:

- DEV: `kubernetes/overlays/dev`
- PROD: `kubernetes/overlays/prod`

Use an Octopus project variable named `Beacon.KustomizePath`:

- scoped to DEV: `kubernetes/overlays/dev`
- scoped to PROD: `kubernetes/overlays/prod`

Set the step's Kustomization file directory to:

`#{Beacon.KustomizePath}`

Enable **Substitute Variables in Files** for:

`kubernetes/overlays/**/kustomization.yaml`

The overlay contains `#{Octopus.Release.Number}` for both image tags and APP_VERSION. Therefore the Octopus release number MUST exactly match the TeamCity image version, e.g. `1.0.27`.

## Release rule

TeamCity build 27 -> images tagged `1.0.27` -> Octopus release `1.0.27`.

Do not rebuild for PROD. Promote the same Octopus release from DEV to PROD.
