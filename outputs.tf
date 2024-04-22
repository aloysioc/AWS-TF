output "vm_aws_ip" {
  value = aws_instance.my_instance.public_ip
}

output "vm_instance_id" {
  value = aws_instance.my_instance.id
}