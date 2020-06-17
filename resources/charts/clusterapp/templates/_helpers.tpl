{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "clusterapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "clusterapp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "clusterapp.releasename" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "clusterapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "clusterapp.labels" -}}
helm.sh/chart: {{ include "clusterapp.chart" . }}
{{ include "clusterapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "clusterapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clusterapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "clusterapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "clusterapp.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "clusterapp.envConfigMap" -}}
{{- printf "%s-%s" .Release.Name "env-configmap" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clusterapp.volumeConfigMap" -}}
{{- printf "%s-%s" .Release.Name "volume-configmap" | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "clusterapp.servicename" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
