
variable "cluster_name" {
  type        = string
  description = "The cluster name"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN"
}

variable "auth_mapping" {}

variable "oidc_provider_issuer" {
  type        = string
  description = "OIDC provider issuer"
}

variable "cluster_auth_endpoint" {
  type        = string
  description = "Cluster endpoint"
}

variable "cluster_auth_ca" {
  type        = string
  description = "Cluster authorization certificate authority"
}

variable "cluster_auth_token" {
  type        = string
  description = "Cluster authorization token"
}

#######

variable "enable_csi_driver_ebs" {
  type        = bool
  description = "Set if the EBS CSI driver will be deployed in the cluster"
  default     = false
}

variable "enable_csi_driver_efs" {
  type        = bool
  description = "Set if the EFS CSI driver will be deployed in the cluster"
  default     = false
}

## https://artifacthub.io/packages/helm/cluster-autoscaler/cluster-autoscaler
variable "autoscaling_controller_version" {
  type        = string
  description = "Autoscaling HelmChart version to be used"
  default     = "9.37.0"
}

variable "autoscaling_controller_expander" {
  type        = string
  description = "Autoscaling expander. Check the [documentation](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-expanders) to see possible combinations. If multiple values informed, don't forget to escape the commas"
  default     = "random"
}

variable "autoscaling_controller_expander_priorities" {
  type        = string
  description = "Autoscaling priorities to be used if autoscaling_controller_expander contains priority"
  default     = ""
}

## https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller
variable "loadbalancer_controller_version" {
  type        = string
  description = "LoadBalancer HelmChart version to be used"
  default     = "1.8.1"
}

## https://artifacthub.io/packages/helm/external-dns/external-dns
variable "externaldns_controller_version" {
  type        = string
  description = "ExternalDNS HelmChart version to be used"
  default     = "1.14.5"
}

## https://artifacthub.io/packages/helm/aws-ebs-csi-driver/aws-ebs-csi-driver
variable "csi_driver_ebs_version" {
  type        = string
  description = "EBS CSI Driver HelmChart version to be used"
  default     = "2.31.0"
}

## https://artifacthub.io/packages/helm/aws-efs-csi-driver/aws-efs-csi-driver
variable "csi_driver_efs_version" {
  type        = string
  description = "EFS CSI Driver HelmChart version to be used"
  default     = "3.0.5"
}

## https://artifacthub.io/packages/helm/metrics-server/metrics-server
variable "metrics_server_version" {
  type        = string
  description = "Metric Server HelmChart version to be used"
  default     = "3.12.1"
}

###### NGINX ingress

variable "install_nginx_ingress" {
  description = "Flag to install NGINX Ingress with NLB"
  type        = bool
  default     = false
}

variable "fullname_override" {
  description = "Override the full name for the NGINX Ingress"
  type        = string
  default     = "ingress-nginx-nlb-default"
}

variable "ingress_class_resource_name" {
  description = "Name of the ingress class resource"
  type        = string
  default     = "nginx-nlb-default"
}

variable "ingress_class_resource_controller_value" {
  description = "Controller value for the ingress class resource"
  type        = string
  default     = "k8s.io/ingress-nginx-nlb-default"
}

variable "ingress_class" {
  description = "Ingress class for the NGINX Ingress"
  type        = string
  default     = "nginx-nlb-default"
}

variable "aws_lb_ssl_cert_arn" {
  description = "ARN of the SSL certificate for the AWS Load Balancer"
  type        = string
  default     = ""
}

variable "external_dns_target" {
  description = "External DNS target for the NGINX Ingress"
  type        = string
  default     = "external-dns"
}

variable "nginx_ingress_version" {
  description = "Version of the NGINX Ingress"
  type        = string
  default     = "4.11.1"
}



### External Secrets
variable "external_secret_chart_version" {
  description = "External Secrets chart version."
  type        = string
  default     = "0.9.20"
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets resources like ServiceAccount and ClusterSecretStore."
  type        = string
  default     = "kube-system"
}

variable "external_secret_name" {
  description = "The name of the ExternalSecret resource."
  type        = string
  default     = "external_secret"
}

variable "secret_store_name" {
  description = "The name of the ClusterSecretStore resource."
  type        = string
  default     = "aws-secrets-manager"
}

variable "external_secret_target_namespace" {
  description = "The namespace where the ExternalSecret resource will be created."
  type        = string
  default     = "kube-system"
}

variable "secret_data" {
  description = "The data for the ExternalSecret."
  type = list(object({
    secretKey = string
    remoteKey = string
    property  = string
  }))
}

variable "external_secret_refresh_interval" {
  description = "Refresh interval for the ExternalSecret resource."
  type        = string
  default     = "1h"
}

variable "service_account_name" {
  description = "The name of the ServiceAccount used for authentication."
  type        = string
  default     = "external-secrets-sa"
}

variable "docker_secret_name" {
  description = "The name of the ExternalSecret resource for Docker registry."
  type        = string
  default     = "docker-registry-secret"
}

variable "docker_secret_namespace" {
  description = "The namespace where the Docker ExternalSecret will be created."
  type        = string
  default     = "default"
}


variable "docker_remote_key" {
  description = "The remote key in the secret store for the Docker config JSON."
  type        = string
  default     = "your-secrets-manager-key"
}

### Argocd
variable "argocd_name" {
  description = "Name of ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of ArgoCD chart"
  type        = string
  default     = "7.3.11"
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_ingress_hostname" {
  description = "Ingress hostname for ArgoCD"
  type        = string
}

variable "argocd_path" {
  description = "Ingress path for ArgoCD"
  type        = string
}

variable "argocd_repositories" {
  description = "ArgoCD repositories"
  type = map(object({
    url      = string
    name     = string
    password = string
    username = string
  }))
  default = {}
}


variable "applicationset_ingress_hostname" {
  description = "Ingress hostname for ApplicationSet of ArgoCD"
  type        = string
}

variable "applicationset_path" {
  description = "Ingress path for ApplicationSet of ArgoCD"
  type        = string
}

variable "ingressclassname" {
  description = "Ingress class name for ArgoCD"
  type        = string
  default     = "alb"
}

variable "install_argocd" {
  description = "Flag to control the installation of ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_projects" {
  description = "List of ArgoCD projects"
  type = map(object({
    name        = string
    description = string
  }))
  default = {}
}