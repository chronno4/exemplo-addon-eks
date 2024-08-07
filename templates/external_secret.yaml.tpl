apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${secret_name}
  namespace: ${namespace}
spec:
  refreshInterval: "${refresh_interval}"
  secretStoreRef:
    name: ${store_name}
    kind: ClusterSecretStore
  target:
    name: ${secret_name}
    creationPolicy: Owner
  data:
    %{ for secret in secret_data }
    - secretKey: ${secret.secretKey}
      remoteRef:
        key: ${secret.remoteKey}
        property: ${secret.property}
    %{ endfor }
