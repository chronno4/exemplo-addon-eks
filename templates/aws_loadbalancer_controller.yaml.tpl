apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-load-balancer-controller
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://aws.github.io/eks-charts
    chart: aws-load-balancer-controller
    targetRevision: ${loadbalancer_controller_version}
    helm:
      values: |
        clusterName: ${cluster_name}
        serviceAccount:
          create: true
          name: aws-load-balancer-controller
          annotations:
            eks.amazonaws.com/role-arn: ${role_arn}
  destination:
    namespace: kube-system
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
