# `argocd-cmp-konduit`

An [ArgoCD](https://argo-cd.readthedocs.io) [Config Management Plugin](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/) for [Konduit](https://github.com/jace-ys/konduit), used to render manifests from Helm values and Kustomize patches written in evaluated configuration languages like [CUE](https://cuelang.org).

## Getting Started

### 1. Install the sidecar

The plugin should run as a [sidecar container](https://argo-cd.readthedocs.io/en/stable/operator-manual/config-management-plugins/#register-the-plugin-sidecar) alongside the ArgoCD repo-server:

```yaml
repoServer:
  extraContainers:
    - name: konduit
      image: ghcr.io/jace-ys/argocd-cmp-konduit:v0.0.1
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      env:
        - name: HELM_CACHE_HOME
          value: /tmp/helm/cache
        - name: HELM_CONFIG_HOME
          value: /tmp/helm/config
        - name: HELM_DATA_HOME
          value: /tmp/helm/data
        - name: CUE_CACHE_DIR
          value: /tmp/cue/cache
        - name: CUE_CONFIG_DIR
          value: /tmp/cue/config
      volumeMounts:
        - name: var-files
          mountPath: /var/run/argocd
        - name: plugins
          mountPath: /home/argocd/cmp-server/plugins
        - name: cmp-tmp
          mountPath: /tmp
  volumes:
    - name: cmp-tmp
      emptyDir: {}
```

### 2. Configure an Application

Reference the plugin in your Application or ApplicationSet's `source.plugin` section:

```yaml
source:
  repoURL: https://github.com/my-org/my-repo.git
  path: path/to/app
  plugin:
    name: konduit-v0.0.1
    parameters:
      - name: evaluator
        string: cue
      - name: helm
        map:
          chart: my-chart
          repoURL: https://charts.example.com
          chartVersion: "1.0.0"
      - name: valueFiles
        array:
          - values.cue
      - name: patchFiles
        array:
          - patches.cue
      - name: scopes
        array:
          - "@data/cluster.json"
```

See [`plugin.yaml`](plugin.yaml) for the full list of available parameters.

The plugin also automatically injects `helm.release` and `helm.namespace` into the scope data, making them available as `#Konduit.helm.release` and `#Konduit.helm.namespace` in CUE.

See the [`examples/`](examples/) directory for a complete working setup.

## Private Helm Repositories

ArgoCD's built-in Helm support reads credentials from [repository secrets](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories). CMPs do not have access to these secrets, so credentials must be provided to Helm directly via its native configuration files, mounted into the sidecar.

### Standard Helm Repositories

Mount a `repositories.yaml` file into the sidecar and point Helm to it using the `HELM_REPOSITORY_CONFIG` environment variable:

```yaml
env:
  - name: HELM_REPOSITORY_CONFIG
    value: /helm-config/repositories.yaml
```

The file follows Helm's standard repository format:

```yaml
apiVersion: ""
generated: "0001-01-01T00:00:00Z"
repositories:
  - name: my-private-repo
    url: https://charts.example.com
    username: my-username
    password: my-password
```

### OCI Registries

Mount a Docker-style `config.json` file into the sidecar and point Helm to it using the `HELM_REGISTRY_CONFIG` environment variable:

```yaml
env:
  - name: HELM_REGISTRY_CONFIG
    value: /helm-config/config.json
```

The file uses Docker's credential format:

```json
{
  "auths": {
    "ghcr.io": {
      "auth": "<base64-encoded username:password>"
    }
  }
}
```

### Example: Mounting Credentials from a Secret

Create a Secret with the config file:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: helm-config
  namespace: argocd
stringData:
  repositories.yaml: |
    apiVersion: ""
    generated: "0001-01-01T00:00:00Z"
    repositories:
      - name: my-private-repo
        url: https://charts.example.com
        username: my-username
        password: my-password
```

Then mount it into the CMP sidecar container on the repo-server:

```yaml
repoServer:
  extraContainers:
    - name: konduit
      ...
      env:
        - name: HELM_REPOSITORY_CONFIG
          value: /helm-config/repositories.yaml
      volumeMounts:
        - name: helm-config
          mountPath: /helm-config
          readOnly: true
  volumes:
    - name: helm-config
      secret:
        secretName: helm-config
```