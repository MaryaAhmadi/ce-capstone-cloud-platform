output "current_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "current_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

output "tf_state_bucket_name" {
  description = "Terraform state bucket name"
  value       = aws_s3_bucket.tf_state.bucket
}
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_1_id" {
  description = "Public subnet 1 ID"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "Public subnet 2 ID"
  value       = aws_subnet.public_2.id
}

output "private_subnet_1_id" {
  description = "Private subnet 1 ID"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "Private subnet 2 ID"
  value       = aws_subnet.private_2.id
}
output "app_instance_1_id" {
  description = "App instance 1 ID"
  value       = aws_instance.app_1.id
}

output "app_instance_2_id" {
  description = "App instance 2 ID"
  value       = aws_instance.app_2.id
}

output "app_instance_3_id" {
  description = "App instance 3 ID"
  value       = aws_instance.app_3.id
}
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.app_tg.arn
}
