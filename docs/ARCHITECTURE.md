# Architecture

## Components
- VPC with 2 public + 2 private subnets
- ALB in public subnets
- EC2 in private subnets
- NAT Gateway for outbound access

## Flow
User → ALB → EC2 instances

## High Availability
Multi-AZ deployment
