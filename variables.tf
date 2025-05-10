variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "prefect_api_key" {
  description = "Prefect Cloud API key"
  type        = string
  sensitive   = true
}

variable "prefect_account_id" {
  description = "Prefect Cloud Account ID"
  type        = string
}

variable "prefect_workspace_id" {
  description = "Prefect Cloud Workspace ID"
  type        = string
}

variable "prefect_api_url" {
  description = "Prefect Cloud API URL"
  type        = string
  default     = "https://api.prefect.cloud/api"
}