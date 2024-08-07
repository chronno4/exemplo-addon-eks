resource "local_file" "argocd_metrics_server_application" {
  content = templatefile("${path.module}/templates/metrics_server.yaml.tpl", {
    metrics_server_version = var.metrics_server_version
  })
  filename = "${path.module}/manifests/metrics_server_application.yaml"
}

data "local_file" "argocd_metrics_server_application" {
  filename = local_file.argocd_metrics_server_application.filename
}

resource "kubectl_manifest" "metrics_server_application" {
  yaml_body  = data.local_file.argocd_metrics_server_application.content
  depends_on = [helm_release.argocd]
}