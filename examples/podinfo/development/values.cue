package values

import "github.com/jace-ys/argocd-cmp-konduit/examples/lib/k8s"

ui: {
	color: "#00b300"
}

resources: k8s.#ResourceRequirements & {
	requests: cpu:    "10m"
	requests: memory: "32Mi"
}
