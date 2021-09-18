#AWS account ID
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
# AWS user ID
output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}
# AWS current Region
output "region" {
  value = data.aws_region.current.name
}
# Private IP
output "private_ip" {
  value = aws_instance.netology.private_ip
}
# ID Subnet
output "id_subnet" {
  value = aws_instance.netology.private_ip
}

