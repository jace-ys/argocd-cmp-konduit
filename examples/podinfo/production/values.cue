package values

import "github.com/jace-ys/argocd-cmp-konduit/examples/lib/k8s"

ui: {
	color: "#b30000"
}

resources: k8s.#ResourceRequirements & {
	requests: cpu:    "100m"
	requests: memory: "256Mi"
}
