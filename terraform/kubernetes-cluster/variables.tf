variable "delta_cert_expiration_seconds" {
  description = "Number of seconds until the Kubernetes certificate expires"
  default     = 315600000  # 10 year
}