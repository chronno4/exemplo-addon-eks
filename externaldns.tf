resource "aws_iam_policy" "externaldns_policy" {
  name_prefix = "EKS${local.normalized_cluster_name}ExternalDNSCtrlIAMPolicy"
  policy      = file("${path.module}/files/externaldns-policy.json")
}

resource "aws_iam_role" "externaldns_role" {
  name = "EKS${local.normalized_cluster_name}ExternalDNSCtrlRole"
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
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:kube-system:external-dns"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "EKS_externaldns_role_attachment" {
  role       = aws_iam_role.externaldns_role.name
  policy_arn = aws_iam_policy.externaldns_policy.arn
}


resource "local_file" "argocd_externaldns_application" {
  content = templatefile("${path.module}/templates/external_dns.yaml.tpl", {
    externaldns_controller_version = var.externaldns_controller_version,
    cluster_name                   = var.cluster_name,
    role_arn                       = aws_iam_role.externaldns_role.arn
  })
  filename = "${path.module}/manifests/externaldns_application.yaml"
}

data "local_file" "argocd_externaldns_application" {
  filename = local_file.argocd_externaldns_application.filename
}

resource "kubectl_manifest" "externaldns_application" {
  yaml_body  = data.local_file.argocd_externaldns_application.content
  depends_on = [aws_iam_role.externaldns_role]
}