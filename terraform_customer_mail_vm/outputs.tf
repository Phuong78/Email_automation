output "customer_vm_public_ip" {
  description = "Địa chỉ IP Public của máy chủ mail khách hàng."
  value       = aws_instance.customer_vm.public_ip
}

output "customer_vm_private_ip" {
  description = "Địa chỉ IP Private của máy chủ mail khách hàng."
  value       = aws_instance.customer_vm.private_ip
}

output "customer_vm_id" {
  description = "ID của EC2 instance máy chủ mail khách hàng."
  value       = aws_instance.customer_vm.id
}