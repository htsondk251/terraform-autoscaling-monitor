variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-example-instance"
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "PROJECT_NAME" {
  type    = string
  default = "demo-autoscaling"
}

variable "VPC_CIDR" {
  type    = string
  default = "172.128.0.0/20"
}

variable "PUBLIC_SUBNET_1A_CIDR" {
  type    = string
  default = "172.128.0.0/24"
}

variable "PUBLIC_SUBNET_1B_CIDR" {
  type    = string
  default = "172.128.1.0/24"
}

variable "PUBLIC_SUBNET_1C_CIDR" {
  type    = string
  default = "172.128.2.0/24"
}

variable "PRIVATE_SUBNET_1A_CIDR" {
  type    = string
  default = "172.128.10.0/24"
}

variable "PRIVATE_SUBNET_1B_CIDR" {
  type    = string
  default = "172.128.11.0/24"
}

variable "PRIVATE_SUBNET_1C_CIDR" {
  type    = string
  default = "172.128.12.0/24"
}

variable "KEY_PAIR" {
  type    = string
  default = "Son-SG"
}

variable "USER_DATA_FILE" {
  type    = string
  default = "config.sh"
}

variable "ASG_DESIRED_CAPACITY" {
  type    = number
  default = 1
}

variable "ASG_MAX_SIZE" {
  type    = number
  default = 5
}

variable "ASG_MIN_SIZE" {
  type    = number
  default = 1
}
