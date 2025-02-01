module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name                   = var.cluster_name
  cluster_version                = var.k8_version
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  create_cluster_security_group = true
  create_node_security_group    = true

  manage_aws_auth_configmap = true
  aws_auth_roles            = local.aws_k8s_role_mapping

  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns    = {}
  }

  eks_managed_node_groups = {
    initial = {
      instance_types = [var.instance_type]
      min_size       = 2
      max_size       = 5
      desired_size   = 4
    }
  }


  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API to Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }

    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }

    ingress_istio_sg = {
      description              = "LB port forward to nodes"
      protocol                 = "TCP"
      from_port                = 30000
      to_port                  = 32767
      type                     = "ingress"
      source_security_group_id = aws_security_group.istio-gateway-lb.id
    }
  }


  tags = {
    Environment = "${var.env_prefix}"
  }

}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_external_secrets             = true
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_cluster_autoscaler           = true
  cluster_autoscaler = {
    set = [
      {
        name  = "extraArgs.scale-down-unneeded-time"
        value = "1m"
      },
      {
        name  = "extraArgs.skip-nodes-with-local-storage"
        value = false
      },
      {
        name  = "extraArgs.skip-nodes-with-system-pods"
        value = false
      }
    ]
  }
}

