apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-secrets
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "https://charts.external-secrets.io"
    chart: "external-secrets"
    targetRevision: "${chart_version}"
    helm:
      values: |
        serviceAccount:
          create: true
          name: external-secrets-sa
          annotations:
            eks.amazonaws.com/role-arn: "${role_arn}"
        installCRDs: true
  destination:
    namespace: ${namespace}
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
