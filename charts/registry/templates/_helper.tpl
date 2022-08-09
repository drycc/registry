{{- define "registry.envs" }}
env:
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
- name: "DRYCC_STORAGE_LOOKUP"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: lookup
- name: "DRYCC_STORAGE_HEALTH"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: health
- name: "DRYCC_STORAGE_BUCKET"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: registry-bucket
- name: "DRYCC_STORAGE_ENDPOINT"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: endpoint
- name: "DRYCC_STORAGE_ACCESSKEY"
  valueFrom:
    secretKeyRef:
      name: storage-creds
      key: accesskey
- name: "DRYCC_STORAGE_SECRETKEY"
  valueFrom:
    secretKeyRef:
      name: storage-creds
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