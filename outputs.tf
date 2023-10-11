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