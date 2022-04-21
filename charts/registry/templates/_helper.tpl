{{- define "registry.envs" -}}
- name: REGISTRY_STORAGE_DELETE_ENABLED
  value: "true"
- name: REGISTRY_LOG_LEVEL
  value: info
- name: "REGISTRY_HTTP_SECRET"
  valueFrom:
    secretKeyRef:
      name: registry-secret
      key: secret
- name: "DRYCC_REGISTRY_REDIRECT"
  valueFrom:
    secretKeyRef:
      name: registry-secret
      key: redirect
- name: "DRYCC_REGISTRY_USERNAME"
  valueFrom:
    secretKeyRef:
      name: registry-secret
      key: username
- name: "DRYCC_REGISTRY_PASSWORD"
  valueFrom:
    secretKeyRef:
      name: registry-secret
      key: password
- name: "DRYCC_MINIO_LOOKUP"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: lookup
- name: "DRYCC_MINIO_BUCKET"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: registry-bucket
- name: "DRYCC_MINIO_ENDPOINT"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: endpoint
- name: "DRYCC_MINIO_ACCESSKEY"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: accesskey
- name: "DRYCC_MINIO_SECRETKEY"
  valueFrom:
    secretKeyRef:
      name: minio-creds
      key: secretkey
{{- end }}

{{/* Generate registry deployment limits */}}
{{- define "registry.limits" -}}
{{- if or (.Values.limitsCpu) (.Values.limitsMemory)}}
resources:
  limits:
    {{- if (.Values.limitsCpu) }}
    cpu: {{.Values.limitsCpu}}
    {{- end }}
    {{- if (.Values.limitsMemory) }}
    memory: {{.Values.limitsMemory}}
    {{- end }}
    {{- if (.Values.limitsHugepages2Mi) }}
    hugepages-2Mi: {{.Values.limitsHugepages2Mi}}
    {{- end }}
    {{- if (.Values.limitsHugepages1Gi) }}
    hugepages-1Gi: {{.Values.limitsHugepages1Gi}}
    {{- end }}
{{- end }}
{{- end }}