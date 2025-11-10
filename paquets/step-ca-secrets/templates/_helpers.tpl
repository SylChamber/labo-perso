{{/*
Expand the name of the chart.
*/}}
{{- define "step-ca-secrets.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expansionne le nom de remplacement de la charte et assure sa présence
*/}}
{{- define "step-ca-secrets.nameOverride" -}}
{{- required "nameOverride est requise" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expansionne le nom de remplacement de la release et assure sa présence
*/}}
{{- define "step-ca-secrets.releaseOverride" -}}
{{- required "releaseOverride est requise" .Values.releaseOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "step-ca-secrets.fullname" -}}
{{- $release := include "step-ca-secrets.releaseOverride" . -}}
{{- $name := include "step-ca-secrets.nameOverride" . -}}
{{- printf "%s-%s" $release $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "step-ca-secrets.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Créer un nom de charte et version de la charte dépendante pour un label
*/}}
{{- define "step-ca-secrets.requiredBy" -}}
{{- printf "%s-%s" (include "step-ca-secrets.nameOverride" .) .Chart.AppVersion | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "step-ca-secrets.labels" -}}
helm.sh/chart: {{ include "step-ca-secrets.chart" . }}
app.kubernetes.io/name: {{ include "step-ca-secrets.nameOverride" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
kubernetes.sylchamber.ca/required-by: {{ include "step-ca-secrets.requiredBy" . }}
{{- end -}}
