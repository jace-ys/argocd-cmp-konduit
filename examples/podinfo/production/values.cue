package values

import "github.com/jace-ys/argocd-cmp-konduit/examples/lib/k8s"

replicaCount: 2

ui: {
	color: "#b30000"
}

resources: k8s.#ResourceRequirements & {
	requests: cpu:    "50m"
	requests: memory: "128Mi"
}
