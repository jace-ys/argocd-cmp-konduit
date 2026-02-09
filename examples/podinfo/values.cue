package values

import "github.com/jace-ys/argocd-cmp-konduit/examples/lib/k8s"

_cluster: k8s.#Cluster & #Konduit.cluster

podAnnotations: k8s.#Annotations & {#cluster: _cluster}

ui: message: "Hello from \(#Konduit.helm.release)-\(_cluster.tags.environment)!"

ingress: {
	enabled:   true
	className: "traefik"
	hosts: [{
		if _cluster.tags.environment == "production" {
			host: "\(#Konduit.helm.release).kind.localhost"
		}
		if _cluster.tags.environment != "production" {
			host: "\(#Konduit.helm.release)-\(_cluster.tags.environment).kind.localhost"
		}

		paths: [{
			path:     "/"
			pathType: "Prefix"
		}]
	}]
}
