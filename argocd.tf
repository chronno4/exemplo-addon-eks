resource "kubernetes_namespace" "argocd" {
  count = var.install_argocd ? 1 : 0
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  count      = var.install_argocd ? 1 : 0
  name       = var.argocd_name
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.argocd_chart_version
  namespace  = var.argocd_namespace
  timeout    = "1200"

  values = [
    <<EOF
server:
  ingress:
    enabled: true
    annotations:
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/backend-protocol: HTTPS
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
      alb.ingress.kubernetes.io/group.name: argocd
applicationSet:
  ingress:
    enabled: true
    annotations:
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/backend-protocol: HTTPS
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
      alb.ingress.kubernetes.io/group.name: argocd
EOF
  ]

  set {
    name  = "nameOverride"
    value = "argocd"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = var.ingressclassname
  }

  set {
    name  = "server.ingress.hostname"
    value = var.argocd_ingress_hostname
  }

  set {
    name  = "server.ingress.path"
    value = var.argocd_path
  }

  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }

  dynamic "set" {
    for_each = var.argocd_repositories
    content {
      name  = "configs.repositories.${set.key}.url"
      value = set.value.url
    }
  }

  dynamic "set" {
    for_each = var.argocd_repositories
    content {
      name  = "configs.repositories.${set.key}.name"
      value = set.value.name
    }
  }

  dynamic "set" {
    for_each = var.argocd_repositories
    content {
      name  = "configs.repositories.${set.key}.password"
      value = set.value.password
    }
  }

  dynamic "set" {
    for_each = var.argocd_repositories
    content {
      name  = "configs.repositories.${set.key}.username"
      value = set.value.username
    }
  }

  set {
    name  = "applicationSet.enabled"
    value = "true"
  }

  set {
    name  = "applicationSet.metrics.enabled"
    value = "true"
  }

  set {
    name  = "applicationSet.ingress.enabled"
    value = "true"
  }

  set {
    name  = "applicationSet.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "applicationSet.ingress.hostname"
    value = var.applicationset_ingress_hostname
  }

  set {
    name  = "applicationSet.ingress.path"
    value = var.applicationset_path
  }
}


resource "kubernetes_manifest" "argocd_project" {
  for_each = var.install_argocd ? var.argocd_projects : {}
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = each.value.name
      namespace = var.argocd_namespace
    }
    spec = {
      description = each.value.description
    }
  }

  depends_on = [helm_release.argocd]
}