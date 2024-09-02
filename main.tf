locals {
  oidc_provider_arn       = var.oidc_provider_arn
  oidc_provider_issuer    = var.oidc_provider_issuer
  normalized_cluster_name = replace(title(replace(var.cluster_name, "/[[:punct:]]/", " ")), "/[[:space:]]/", "")
  merged_map_roles = distinct(concat(
    try(yamldecode(data.kubernetes_config_map.default.data.mapRoles), []),
    var.auth_mapping,
  ))
}

provider "kubernetes" {
  host                   = var.cluster_auth_endpoint
  cluster_ca_certificate = base64decode(var.cluster_auth_ca)
  token                  = var.cluster_auth_token
}

provider "helm" {
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm"

  kubernetes {
    host                   = var.cluster_auth_endpoint
    cluster_ca_certificate = base64decode(var.cluster_auth_ca)
    token                  = var.cluster_auth_token
  }
}

terraform {
  required_version = ">= 1.3"

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
  }
}


provider "kubectl" {
  apply_retry_count      = 5
  host                   = var.cluster_auth_endpoint
  cluster_ca_certificate = base64decode(var.cluster_auth_ca)
  token                  = var.cluster_auth_token
}

data "http" "wait_for_cluster" {
  url      = format("%s/healthz", var.cluster_auth_endpoint)
  insecure = true
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [data.http.wait_for_cluster]

  create_duration = "60s"
}

data "kubernetes_config_map" "default" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  depends_on = [data.http.wait_for_cluster, time_sleep.wait_60_seconds]
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  depends_on = [data.http.wait_for_cluster, time_sleep.wait_60_seconds]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    "mapRoles" = yamlencode(local.merged_map_roles)
  }
  force = true
}



