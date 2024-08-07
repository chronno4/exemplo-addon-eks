apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: ${store_name}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${region}
      auth:
        jwt:
          serviceAccountRef:
            name: ${service_account_name}
            namespace: ${namespace}
