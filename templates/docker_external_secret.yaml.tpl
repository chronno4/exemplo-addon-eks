apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${docker_secret_name}
  namespace: ${namespace}
spec:
  refreshInterval: "1s"
  secretStoreRef:
    name: ${store_name}
    kind: ClusterSecretStore
  target:
    name: ${docker_secret_name}
    creationPolicy: Owner
    template:
      type: kubernetes.io/dockerconfigjson
      data:
        .dockerconfigjson: '{"auths":{"harbor-dev.matera.com":{"username":"{{ .username }}","password":"{{ .password }}","email":"{{ .mail }}","auth":"{{ printf "%s:%s" .username .password | b64enc }}"}}}'
  data:
    - secretKey: username
      remoteRef:
        key: ${docker_remote_key}
        property: username
    - secretKey: password
      remoteRef:
        key: ${docker_remote_key}
        property: password
    - secretKey: mail
      remoteRef:
        key: ${docker_remote_key}
        property: mail
