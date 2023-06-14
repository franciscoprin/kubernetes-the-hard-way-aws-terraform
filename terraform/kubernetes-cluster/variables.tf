variable "delta_cert_expiration_seconds" {
  description = "Number of seconds until the Kubernetes certificate expires"
  default     = 31536000 # 1 year
}