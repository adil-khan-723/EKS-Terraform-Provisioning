output "private_subnet_ids" {
    description = "private subnet ids"
    value = aws_subnet.private[*].id
}