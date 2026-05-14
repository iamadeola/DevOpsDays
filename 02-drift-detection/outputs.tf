output "instance_public_ip" {
  value = aws_instance.demo.public_ip
}

output "security_group_id" {
  value = aws_security_group.demo.id
}
