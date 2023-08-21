{{- define "voting-chart.labels"}}
app: {{ .Values.AppName }}
{{- end}}
{{- define "postgres.env"}}
env:
- name: POSTGRES_USER
  value: "postgres"
- name:  POSTGRES_PASSWORD
  value: "postgres"
- name: POSTGRES_HOST_AUTH_METHOD
  value: trust
{{- end}}
