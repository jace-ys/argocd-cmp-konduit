# Examples

A working demo that deploys [podinfo](https://github.com/stefanprodan/podinfo) across development, staging, and production environments using ArgoCD with the Konduit CMP.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [mise](https://mise.jdx.dev)

## Running

```sh
# Create a Kind cluster, install ArgoCD + Traefik, and deploy the example applications
mise run examples --use-local-image

# Tear down the cluster
mise run examples:destroy
```

Once running, the ArgoCD UI is available at [http://argocd.kind.localhost](http://argocd.kind.localhost) (username: `admin`, password: `admin`).

The podinfo applications are accessible at:

| Environment | URL |
|---|---|
| Production | [http://podinfo.kind.localhost](http://podinfo.kind.localhost) |
| Staging | [http://podinfo-staging.kind.localhost](http://podinfo-staging.kind.localhost) |
| Development | [http://podinfo-development.kind.localhost](http://podinfo-development.kind.localhost) |
