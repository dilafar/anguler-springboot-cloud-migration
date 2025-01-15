package main

deny[msg] {
  input.kind == "Service"
  not input.spec.type == "LoadBalancer"
  not input.spec.type == "ClusterIP"
  not input.spec.type == "ExternalName"

  msg := "Service type must be LoadBalancer, ClusterIP, or ExternalName"
}


#deny[msg] {
#  input.kind = "Deployment"
#  not input.spec.template.spec.containers[0].securityContext.runAsNonRoot = true
#  msg = "Containers must not run as root - use runAsNonRoot wihin container security context"
#}


