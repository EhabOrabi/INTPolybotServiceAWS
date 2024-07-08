variable "env" {
  description = "Environment for the infrastructure (e.g., dev, stage, prod)"
  type        = string
  default     = "dev"  # Set a default value appropriate for your environment
}
