package main
import rego.v1

deny contains msg if {
	input.kind == "Service"

	not input.spec.type == "LoadBalancer"
	not input.spec.type == "ClusterIP"
    not input.spec.type == "ExternalName"
	not input.spec.type == "NodePort"

	msg := "Service type must be LoadBalancer or ClusterIP"

}

#deny[msg] {
#  input.kind = "Deployment"
#  not input.spec.template.spec.containers[0].securityContext.runAsNonRoot = true
#  msg = "Containers must not run as root - use runAsNonRoot wihin container security context"
#}


