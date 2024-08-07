apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: ${namespace}
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}
