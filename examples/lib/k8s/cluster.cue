package k8s

#Cluster: {
	name:        string
	tags:        #ClusterTags
	attributes?: #ClusterAttributes
}

#ClusterTags: {
	environment: string
	region:      string
}

#ClusterAttributes: {
	vault?: enabled: *false | bool
	istio?: enabled: *false | bool
}
