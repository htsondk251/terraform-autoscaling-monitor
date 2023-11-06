#output "public_ip" {
#  value       = aws_instance.example.public_ip
#  description = "The public IP of the Instance"
#}

#output "instance_id" {
#  value = aws_instance.example.id
#  description = "id of instance"
#}

output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

output "VPC_ID" {
  value = aws_vpc.vpc.id
}

# output "PUBLIC_SUBNET_1A_ID" {
#   value = aws_subnet.public-subnet-1a.id
# }
# output "PUBLIC_SUBNET_1B_ID" {
#   value = aws_subnet.public-subnet-1b.id
# }
# output "PRIVATE_SUBNET_1A_ID" {
#   value = aws_subnet.private-subnet-1a.id
# }

# output "PRIVATE_SUBNET_1B_ID" {
#   value = aws_subnet.private-subnet-1b.id
# }
