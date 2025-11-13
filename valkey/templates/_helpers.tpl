{{/*
Expand the name of the chart.
*/}}
{{- define "valkey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "valkey.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "valkey.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "valkey.labels" -}}
helm.sh/chart: {{ include "valkey.chart" . }}
{{ include "valkey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "valkey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "valkey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "valkey.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "valkey.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creating Image Pull Secrets
*/}}
{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{- define "valkey.secretName" -}}
{{- if .Values.imagePullSecrets.nameOverride }}
{{- .Values.imagePullSecrets.nameOverride }}
{{- else }}
{{- printf "%s-regcred" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Check if there are any users with inline passwords
*/}}
{{- define "valkey.hasInlinePasswords" -}}
{{- $hasInlinePasswords := false -}}
{{- range .Values.auth.aclUsers -}}
  {{- if .password -}}
    {{- $hasInlinePasswords = true -}}
  {{- end -}}
{{- end -}}
{{- $hasInlinePasswords -}}
{{- end -}}

{{/*
Validate auth configuration
*/}}
{{- define "valkey.validateAuthConfig" -}}
{{- if .Values.auth.enabled }}
  {{- if not (or .Values.auth.aclUsers .Values.auth.aclConfig) }}
    {{- fail "auth.enabled is true but no authentication method is configured. Please provide auth.aclUsers or auth.aclConfig" }}
  {{- end }}
  {{- if .Values.auth.aclUsers }}
    {{- $hasUsersExistingSecret := .Values.auth.usersExistingSecret }}
    {{- range .Values.auth.aclUsers }}
      {{- if not .name }}
        {{- fail "Each user in auth.aclUsers must have a 'name' field" }}
      {{- end }}
      {{- if not .permissions }}
        {{- fail (printf "User '%s' in auth.aclUsers must have a 'permissions' field" .name) }}
      {{- end }}
      {{- if not (or .password $hasUsersExistingSecret) }}
        {{- fail (printf "User '%s' must have either 'password' field or auth.usersExistingSecret must be set" .name) }}
      {{- end }}
      {{- if and .passwordKey (not $hasUsersExistingSecret) }}
        {{- fail (printf "User '%s' has passwordKey but auth.usersExistingSecret is not set" .name) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}