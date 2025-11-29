variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "ssh_public_key" {
  description = "Public SSH key contents for the EC2 instance."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the matching SSH private key so Ansible can connect."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the app host."
  type        = string
  default     = "t3.medium"
}

variable "allow_ssh_cidr" {
  description = "CIDR block allowed to SSH to the host."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_repo_url" {
  description = "Git repository URL of the application."
  type        = string
  default     = "https://github.com/Godwin-T/DevOps-Stage-6.git"
}

variable "app_repo_version" {
  description = "Git branch or tag to deploy."
  type        = string
  default     = "main"
}

variable "ansible_user" {
  description = "Remote user Ansible should SSH as."
  type        = string
  default     = "ubuntu"
}

variable "base_domain" {
  description = "Primary domain that Traefik should serve."
  type        = string
}

variable "api_base_path" {
  description = "Shared API prefix (e.g. /api)."
  type        = string
  default     = "/api"
}

variable "traefik_acme_email" {
  description = "Email address used for Let's Encrypt registration."
  type        = string
}

variable "zipkin_subdomain" {
  description = "Subdomain for Zipkin UI."
  type        = string
  default     = "zipkin"
}

variable "tags" {
  description = "Map of additional tags to apply to AWS resources."
  type        = map(string)
  default     = {}
}

variable "auth_jwt_secret" {
  description = "JWT secret for the auth API."
  type        = string
  sensitive   = true
}

variable "todos_jwt_secret" {
  description = "JWT secret for todos API."
  type        = string
  sensitive   = true
}

variable "users_jwt_secret" {
  description = "JWT secret for users API."
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "Redis host name or address."
  type        = string
  default     = "redis"
}

variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "redis_channel" {
  description = "Redis pub/sub channel."
  type        = string
  default     = "todo_events"
}

variable "zipkin_url" {
  description = "Zipkin collector URL."
  type        = string
  default     = "http://zipkin:9411/api/v2/spans"
}

variable "root_volume_size" {
  description = "Root EBS volume size (GB)."
  type        = number
  default     = 30
}
