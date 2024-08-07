data "http" "csi_driver_efs_policy_content" {
  count = var.enable_csi_driver_efs ? 1 : 0

  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json"
}

resource "aws_iam_policy" "csi_driver_efs_policy" {
  count = var.enable_csi_driver_efs ? 1 : 0

  name_prefix = "EKS${local.normalized_cluster_name}CSIDriverEFSIAMPolicy"
  policy      = data.http.csi_driver_efs_policy_content[0].response_body
}

resource "aws_iam_role" "csi_driver_efs_role" {
  count = var.enable_csi_driver_efs ? 1 : 0

  name = "EKS${local.normalized_cluster_name}CSIDriverEFSRole"
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
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:kube-system:efs-csi-controller-sa"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "EKS_csi_driver_efs_role_attachment" {
  count = var.enable_csi_driver_efs ? 1 : 0

  role       = aws_iam_role.csi_driver_efs_role[0].name
  policy_arn = aws_iam_policy.csi_driver_efs_policy[0].arn
}

# resource "helm_release" "csi_driver_efs_helm" {
#   count = var.enable_csi_driver_efs ? 1 : 0

#   namespace  = "kube-system"
#   name       = "aws-efs-csi-driver"
#   repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
#   chart      = "aws-efs-csi-driver"
#   version    = var.csi_driver_efs_version

#   set {
#     name  = "controller.serviceAccount.create"
#     value = "true"
#   }

#   set {
#     name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.csi_driver_efs_role[0].arn
#   }
# }



resource "local_file" "argocd_csi_driver_efs_application" {
  count = var.enable_csi_driver_efs ? 1 : 0

  content = templatefile("${path.module}/templates/csi_driver_efs.yaml.tpl", {
    csi_driver_efs_version  = var.csi_driver_efs_version,
    csi_driver_efs_role_arn = aws_iam_role.csi_driver_efs_role[0].arn
  })
  filename = "${path.module}/manifests/csi_driver_efs_application.yaml"
}

data "local_file" "argocd_csi_driver_efs_application" {
  count    = var.enable_csi_driver_efs ? 1 : 0
  filename = local_file.argocd_csi_driver_efs_application[0].filename
}

resource "kubectl_manifest" "csi_driver_efs_application" {
  count      = var.enable_csi_driver_efs ? 1 : 0
  yaml_body  = data.local_file.argocd_csi_driver_efs_application[0].content
  depends_on = [aws_iam_role.csi_driver_efs_role]
}