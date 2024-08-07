apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: csi-driver-efs
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes-sigs.github.io/aws-efs-csi-driver/
    chart: aws-efs-csi-driver
    targetRevision: "${csi_driver_efs_version}"
    helm:
      values: |
        controller:
          serviceAccount:
            create: true
            name: efs-csi-controller-sa
            annotations:
              eks.amazonaws.com/role-arn: ${csi_driver_efs_role_arn}
        node:
          serviceAccount:
            create: true
            name: efs-csi-node-sa
            annotations:
              eks.amazonaws.com/role-arn: ${csi_driver_efs_role_arn}
  destination:
    namespace: kube-system
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
