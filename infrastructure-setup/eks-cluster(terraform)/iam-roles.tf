locals {
  aws_k8s_role_mapping = [
    {
      rolearn  = aws_iam_role.external-admin.arn
      username = "admin"
      groups   = ["none"]
    },
    {
      rolearn  = aws_iam_role.external-developer.arn
      username = "developer"
      groups   = ["none"]
    }
  ]
}
resource "aws_iam_role" "external-admin" {
  name = "external-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.user_for_admin_role
        }
      },
    ]
  })

  inline_policy {
    name = "external_admin_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["eks:DescribeCluster"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_role" "external-developer" {
  name = "external-developer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.user_for_dev_role
        }
      },
    ]
  })

  inline_policy {
    name = "external_developer_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["eks:DescribeCluster"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

resource "aws_iam_role" "externalsecrets-role" {
  name = "externalsecrets_sa_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      },
    ]
  })

  inline_policy {
    name = "externalsecrets_sa_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Resource = "*"
          Action = [
            "secretsmanager:GetRandomPassword",
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds",
            "secretsmanager:ListSecrets",
            "secretsmanager:BatchGetSecretValue"
          ]
        },
      ]
    })
  }
}

resource "aws_iam_role" "externaldns-role" {
  name = "externaldns_sa_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      },
    ]
  })

  inline_policy {
    name = "externaldns_sa_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "route53:ChangeResourceRecordSets"
          ],
          "Resource" : [
            "arn:aws:route53:::hostedzone/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
          ],
          "Resource" : [
            "*"
          ]
        }
      ]
    })
  }
}