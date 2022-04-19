{{- define "registry.envs" -}}
{{- if eq .Values.global.minioLocation "on-cluster" }}
- name: "DRYCC_MINIO_ENDPOINT"
  value: http://${DRYCC_MINIO_SERVICE_HOST}:${DRYCC_MINIO_SERVICE_PORT}
{{- else }}
- name: "DRYCC_MINIO_ENDPOINT"
  value: "{{ .Values.minio.endpoint }}"
{{- end }}
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