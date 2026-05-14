output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID of the created VPC"
}

output "subnet_id" {
  value       = aws_subnet.public.id
  description = "Subnet ID of the public subnet"
}

output "instance_public_ip" {
  value       = aws_instance.demo.public_ip
  description = "Public IP of the EC2 demo instance"
}

output "security_group_id" {
  value       = aws_security_group.ec2.id
  description = "Security Group ID of the EC2 demo instance"
}


output "instance_public_dns" {
  value       = aws_instance.demo.public_dns
  description = "Public DNS of the EC2 demo instance"
}