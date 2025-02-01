package main

deny[msg] {
	input.kind == "Service"
	not input.spec.type == "LoadBalancer"
	not input.spec.type == "ClusterIP"
	not input.spec.type == "ExternalName"
	not input.spec.type == "NodePort"

	msg := "Service type must be LoadBalancer or ClusterIP, NodePort only for GKE"
}

deny[msg] {
	input.kind == "Deployment"
	not input.spec.template.spec.containers[0].securityContext.runAsNonRoot
	msg := "Containers must not run as root - use runAsNonRoot within container security context"
}


