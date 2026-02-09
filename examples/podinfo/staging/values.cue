package values

import "github.com/jace-ys/argocd-cmp-konduit/examples/lib/k8s"

ui: {
	color: "#ffb300"
}

resources: k8s.#ResourceRequirements & {
	requests: cpu:    "25m"
	requests: memory: "64Mi"
}
