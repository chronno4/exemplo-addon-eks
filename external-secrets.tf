resource "aws_iam_policy" "external_secrets_policy" {
  name_prefix = "EKS${local.normalized_cluster_name}ExternalSecretsCtrlIAMPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sts:AssumeRoleWithWebIdentity",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "external_secrets_role" {
  name = "EKS${local.normalized_cluster_name}ExternalSecretsCtrlRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
          Federated = local.oidc_provider_arn
        },
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:external-secrets-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_role_attachment" {
  role       = aws_iam_role.external_secrets_role.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}

resource "local_file" "argocd_external_secrets_application" {
  content = templatefile("${path.module}/templates/applications-external-secrets.yaml.tpl", {
    chart_version = var.external_secret_chart_version,
    role_arn      = aws_iam_role.external_secrets_role.arn,
    namespace     = var.external_secrets_namespace
  })
  filename = "${path.module}/applications/applications-external-secrets.yaml"
}

data "local_file" "argocd_external_secrets_application" {
  filename = local_file.argocd_external_secrets_application.filename
}

resource "kubectl_manifest" "external_secrets_application" {
  yaml_body  = data.local_file.argocd_external_secrets_application.content
  depends_on = [aws_iam_role.external_secrets_role, helm_release.argocd]
}


resource "local_file" "service_account" {
  content = templatefile("${path.module}/templates/service_account.yaml.tpl", {
    namespace = var.external_secrets_namespace,
    role_arn  = aws_iam_role.external_secrets_role.arn
  })
  filename = "${path.module}/manifests/service_account.yaml"
}

resource "local_file" "cluster_secret_store" {
  content = templatefile("${path.module}/templates/cluster_secret_store.yaml.tpl", {
    namespace            = var.external_secrets_namespace,
    store_name           = var.secret_store_name,
    region               = data.aws_region.current.name,
    service_account_name = var.service_account_name
  })
  filename = "${path.module}/manifests/cluster_secret_store.yaml"
}

resource "local_file" "external_secret" {
  content = templatefile("${path.module}/templates/external_secret.yaml.tpl", {
    secret_name      = var.external_secret_name,
    namespace        = var.external_secret_target_namespace,
    store_name       = var.secret_store_name,
    secret_data      = var.secret_data,
    refresh_interval = var.external_secret_refresh_interval
  })
  filename = "${path.module}/manifests/external_secret.yaml"
}

resource "local_file" "docker_external_secret" {
  content = templatefile("${path.module}/templates/docker_external_secret.yaml.tpl", {
    docker_secret_name = var.docker_secret_name,
    namespace          = var.docker_secret_namespace,
    store_name         = var.secret_store_name,
    docker_remote_key  = var.docker_remote_key
  })
  filename = "${path.module}/manifests/docker_external_secret.yaml"
}

data "local_file" "service_account" {
  filename = local_file.service_account.filename
}

data "local_file" "cluster_secret_store" {
  filename = local_file.cluster_secret_store.filename
}

data "local_file" "external_secret" {
  filename = local_file.external_secret.filename
}

data "local_file" "docker_external_secret" {
  filename = local_file.docker_external_secret.filename
}

resource "kubectl_manifest" "service_account" {
  yaml_body  = data.local_file.service_account.content
  depends_on = [kubectl_manifest.service_account]
}

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body  = data.local_file.cluster_secret_store.content
  depends_on = [kubectl_manifest.service_account]
}

resource "kubectl_manifest" "external_secret" {
  yaml_body  = data.local_file.external_secret.content
  depends_on = [kubectl_manifest.cluster_secret_store]
}


resource "kubectl_manifest" "docker_external_secret" {
  yaml_body  = data.local_file.docker_external_secret.content
  depends_on = [kubectl_manifest.cluster_secret_store]
}
