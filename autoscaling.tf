resource "aws_iam_policy" "autoscaling_policy" {
  name_prefix = "EKS${local.normalized_cluster_name}ASGCtrlIAMPolicy"
  policy      = file("${path.module}/files/cluster-autoscaler-policy.json")
}

resource "aws_iam_role" "autoscaling_role" {
  name = "EKS${local.normalized_cluster_name}ASGCtrlRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_provider_issuer}:aud" = "sts.amazonaws.com",
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "EKS_autoscaling_role_attachment" {
  role       = aws_iam_role.autoscaling_role.name
  policy_arn = aws_iam_policy.autoscaling_policy.arn
}

data "aws_region" "current" {}


resource "local_file" "argocd_autoscaler_application" {
  content = templatefile("${path.module}/templates/cluster_autoscaler.yaml.tpl", {
    autoscaling_controller_version  = var.autoscaling_controller_version,
    cluster_name                    = var.cluster_name,
    aws_region                      = data.aws_region.current.name,
    autoscaling_role_arn            = aws_iam_role.autoscaling_role.arn,
    autoscaling_controller_expander = var.autoscaling_controller_expander,
    expander_priorities_yaml        = var.autoscaling_controller_expander_priorities
  })
  filename = "${path.module}/manifests/autoscaler_application.yaml"
}

data "local_file" "argocd_autoscaler_application" {
  filename = local_file.argocd_autoscaler_application.filename
}

resource "kubectl_manifest" "autoscaler_application" {
  yaml_body  = data.local_file.argocd_autoscaler_application.content
  depends_on = [aws_iam_role.autoscaling_role]
}