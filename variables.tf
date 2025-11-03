variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to prefix resources"
  type        = string
  default     = "terraform-lab"
}

variable "aws_profile" {
  description = "AWS profile to use (leave empty for default credentials)"
  type        = string
  default     = ""
}

