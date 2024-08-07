apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-autoscaler
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes.github.io/autoscaler
    chart: cluster-autoscaler
    targetRevision: "${autoscaling_controller_version}"
    helm:
      values: |
        extraArgs:
          scale-down-utilization-threshold: 0.1
          expander: ${autoscaling_controller_expander}
        expanderPriorities: |-
          50:
            - SPOT.*
          10: 
            - .*
        autoDiscovery:
          clusterName: ${cluster_name}
        awsRegion: ${aws_region}
        rbac:
          serviceAccount:
            create: true
            name: cluster-autoscaler
            annotations:
              eks.amazonaws.com/role-arn: ${autoscaling_role_arn}
  destination:
    namespace: kube-system
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    retry:
      limit: 2
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m0s
    syncOptions:
    - CreateNamespace=true
