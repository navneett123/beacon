ARG OCTOPUS_IMAGE=octopusdeploy/octopusdeploy:2026.2.13319
FROM ${OCTOPUS_IMAGE}
USER root
ARG KUBECTL_VERSION=v1.35.2
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq findutils coreutils \
    && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && curl -fsSLo /tmp/kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum --check \
    && chmod 0755 /usr/local/bin/kubectl \
    && kubectl version --client \
    && rm -rf /var/lib/apt/lists/* /tmp/kubectl.sha256
USER octopus
