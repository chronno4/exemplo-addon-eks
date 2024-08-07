data "http" "csi_driver_ebs_policy_content" {
  count = var.enable_csi_driver_ebs ? 1 : 0

  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v1.17.0/docs/example-iam-policy.json"
}

resource "aws_iam_policy" "csi_driver_ebs_policy" {
  count = var.enable_csi_driver_ebs ? 1 : 0

  name_prefix = "EKS${local.normalized_cluster_name}CSIDriverEBSIAMPolicy"
  policy      = data.http.csi_driver_ebs_policy_content[0].response_body
}

resource "aws_iam_role" "csi_driver_ebs_role" {
  count = var.enable_csi_driver_ebs ? 1 : 0

  name = "EKS${local.normalized_cluster_name}CSIDriverEBSRole"

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
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "EKS_csi_driver_ebs_role_attachment" {
  count = var.enable_csi_driver_ebs ? 1 : 0

  role       = aws_iam_role.csi_driver_ebs_role[0].name
  policy_arn = aws_iam_policy.csi_driver_ebs_policy[0].arn
}


resource "local_file" "argocd_csi_driver_ebs_application" {
  count = var.enable_csi_driver_ebs ? 1 : 0

  content = templatefile("${path.module}/templates/csi_driver_ebs.yaml.tpl", {
    csi_driver_ebs_version  = var.csi_driver_ebs_version,
    csi_driver_ebs_role_arn = aws_iam_role.csi_driver_ebs_role[0].arn
  })
  filename = "${path.module}/manifests/csi_driver_ebs_application.yaml"
}

data "local_file" "argocd_csi_driver_ebs_application" {
  count    = var.enable_csi_driver_ebs ? 1 : 0
  filename = local_file.argocd_csi_driver_ebs_application[0].filename
}

resource "kubectl_manifest" "csi_driver_ebs_application" {
  count      = var.enable_csi_driver_ebs ? 1 : 0
  yaml_body  = data.local_file.argocd_csi_driver_ebs_application[0].content
  depends_on = [aws_iam_role.csi_driver_ebs_role, helm_release.argocd]
}