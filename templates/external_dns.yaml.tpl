apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-dns
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes-sigs.github.io/external-dns/
    chart: external-dns
    targetRevision: ${externaldns_controller_version}
    helm:
      values: |
        serviceAccount:
          create: true
          name: external-dns
          annotations:
            eks.amazonaws.com/role-arn: ${role_arn}
        policy: sync
        txtOwnerId: ${cluster_name}
        txtPrefix: eks-${cluster_name}
        sources:
          - service
          - ingress
        interval: "30s"
  destination:
    namespace: kube-system
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
