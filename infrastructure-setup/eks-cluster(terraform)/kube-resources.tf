resource "kubernetes_namespace" "banking_ns" {
  metadata {
    name = "banking-ns"

    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_role" "namespace_viewer" {
  metadata {
    name      = "namespace-viewer"
    namespace = "banking-ns"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "configmaps", "persistentvolumes"]
    verbs      = ["get", "list", "watch", "describe"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "describe"]
  }
}

resource "kubernetes_role_binding" "namespace_viewer" {
  metadata {
    name      = "namespace-viewer"
    namespace = "banking-ns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "namespace-viewer"
  }
  subject {
    kind      = "User"
    name      = "developer"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch", "describe"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-viewer"
  }
  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_service_account" "externalsecrets_sa" {
  depends_on = [aws_iam_role.externalsecrets-role]
  metadata {
    name      = "externalsecrets-sa"
    namespace = "banking-ns"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externalsecrets-role.arn
    }
  }
}

resource "kubernetes_service_account" "externaldns_sa" {
  depends_on = [aws_iam_role.externaldns-role]
  metadata {
    name      = "externaldns-sa"
    namespace = "external-dns"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns-role.arn
    }
  }
}
