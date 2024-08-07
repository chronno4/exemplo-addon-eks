data "http" "loadbalancer_policy_content" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "loadbalancer_policy" {
  name_prefix = "EKS${local.normalized_cluster_name}LBCtrlIAMPolicy"
  policy      = data.http.loadbalancer_policy_content.response_body
}

resource "aws_iam_role" "loadbalancer_role" {
  name = "EKS${local.normalized_cluster_name}LBCtrlRole"

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
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "EKS_loadbalancer_role_attachment" {
  role       = aws_iam_role.loadbalancer_role.name
  policy_arn = aws_iam_policy.loadbalancer_policy.arn
}



resource "local_file" "argocd_loadbalancer_controller_application" {
  content = templatefile("${path.module}/templates/aws_loadbalancer_controller.yaml.tpl", {
    loadbalancer_controller_version = var.loadbalancer_controller_version,
    cluster_name                    = var.cluster_name,
    role_arn                        = aws_iam_role.loadbalancer_role.arn
  })
  filename = "${path.module}/manifests/aws_loadbalancer_controller_application.yaml"
}

data "local_file" "argocd_loadbalancer_controller_application" {
  filename = local_file.argocd_loadbalancer_controller_application.filename
}

resource "kubectl_manifest" "aws_loadbalancer_controller_application" {
  yaml_body  = data.local_file.argocd_loadbalancer_controller_application.content
  depends_on = [aws_iam_role.loadbalancer_role, helm_release.argocd]
}