data "http" "nginx_policy_content" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json"
}

resource "aws_iam_role" "nginx_ingress_acm_role" {
  name = "EKS${local.normalized_cluster_name}nginxingressacmrole"

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
            "${local.oidc_provider_issuer}:sub" = "system:serviceaccount:ingress-nginx:ingress-nginx"
          }
        }
      },
    ]
  })
}


resource "aws_iam_policy" "nginx_ingress_acm_policy" {
  name_prefix = "EKS${local.normalized_cluster_name}nginxingressacmpolicy"
  policy      = data.http.nginx_policy_content.response_body
  description = "Policy to allow access to ACM certificates and NLB for NGINX Ingress"
}

resource "aws_iam_role_policy_attachment" "nginx_ingress_acm_attachment" {
  role       = aws_iam_role.nginx_ingress_acm_role.name
  policy_arn = aws_iam_policy.nginx_ingress_acm_policy.arn
}


resource "local_file" "argocd_ingress_nginx_application" {
  content = templatefile("${path.module}/templates/applications-ingress-nginx.yaml.tpl", {
    fullname_override                       = var.fullname_override,
    ingress_class_resource_name             = var.ingress_class_resource_name,
    ingress_class_resource_controller_value = var.ingress_class_resource_controller_value,
    ingress_class                           = var.ingress_class,
    aws_lb_ssl_cert_arn                     = var.aws_lb_ssl_cert_arn,
    external_dns_target                     = var.external_dns_target,
    nginx_ingress_version                   = var.nginx_ingress_version,
    nginx_role_arn                          = aws_iam_role.nginx_ingress_acm_role.arn
  })
  filename = "${path.module}/applications/applications-ingress-nginx.yaml"
}
data "local_file" "argocd_ingress_nginx_application" {
  filename = local_file.argocd_ingress_nginx_application.filename
}

resource "kubectl_manifest" "ingress_application" {
  count      = var.install_nginx_ingress ? 1 : 0
  yaml_body  = data.local_file.argocd_ingress_nginx_application.content
  depends_on = [aws_iam_role.nginx_ingress_acm_role, helm_release.argocd]
}


