package main

deny[msg] {
  input.kind == "Service"
  not (input.spec.type == "LoadBalancer" or input.spec.type == "ClusterIP")
  msg = "Service type must be LoadBalancer or ClusterIP"
}

#deny[msg] {
#  input.kind = "Deployment"
#  not input.spec.template.spec.containers[0].securityContext.runAsNonRoot = true
#  msg = "Containers must not run as root - use runAsNonRoot wihin container security context"
#}