apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ingress-nginx
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes.github.io/ingress-nginx
    chart: ingress-nginx
    targetRevision: "${nginx_ingress_version}"
    helm:
      values: |
        fullnameOverride: "${fullname_override}"
        controller:
          ingressClassResource:
            name: "${ingress_class_resource_name}"
            controllerValue: "${ingress_class_resource_controller_value}"
          ingressClass: "${ingress_class}"
          annotations:
            nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
          service:
            targetPorts:
              https: http
            annotations:
              service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
              service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
              service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
              service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
              service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${aws_lb_ssl_cert_arn}
              service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS13-1-2-2021-06"
              service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
              service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
              service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
          serviceAccount:
            create: "true"
            name: "ingress-nginx"
          annotations:
            eks.amazonaws.com/role-arn: ${nginx_role_arn}
          podAnnotations:
            external-dns.alpha.kubernetes.io/target: "${external_dns_target}"
  destination:
    namespace: ingress-nginx
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
