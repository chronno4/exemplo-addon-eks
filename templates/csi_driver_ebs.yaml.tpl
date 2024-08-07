apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: csi-driver-ebs
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://kubernetes-sigs.github.io/aws-ebs-csi-driver
    chart: aws-ebs-csi-driver
    targetRevision: "${csi_driver_ebs_version}"
    helm:
      values: |
        controller:
          serviceAccount:
            create: true
            name: ebs-csi-controller
            annotations:
              eks.amazonaws.com/role-arn: ${csi_driver_ebs_role_arn}
          sidecars:
            snapshotter:
              forceEnable: true
  destination:
    namespace: kube-system
    server: 'https://kubernetes.default.svc'
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
    - CreateNamespace=true
