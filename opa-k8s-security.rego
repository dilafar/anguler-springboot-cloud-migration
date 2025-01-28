package main
import rego.v1

deny[msg] {
  input.kind == "Service"
  not (input.spec.type == "LoadBalancer" 
       or input.spec.type == "ClusterIP" 
       or input.spec.type == "ExternalName" 
       or input.spec.type == "NodePort")
  msg := "Service type must be LoadBalancer or ClusterIP, NodePort only for GKE"
}

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.containers[0].securityContext.runAsNonRoot == true
  msg := "Containers must not run as root - use runAsNonRoot within container security context"
}