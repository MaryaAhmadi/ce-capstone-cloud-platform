# 🚀 Production-Ready AWS Cloud Platform (Capstone Project)

Production-ready AWS cloud platform built as a capstone project for Cloud Engineering bootcamp.


---

## 📌 Project Overview

This project is a production-like cloud platform built on AWS using Terraform.  
The goal was to design a secure, scalable, and observable system — not just a simple demo.

The architecture follows real-world best practices including:
- Private compute layer
- Public entry via load balancer
- Infrastructure as Code (Terraform)
- Monitoring and cost control

---

## 🎯 Goals

- Build a production-style cloud architecture
- Implement secure networking (public/private subnets)
- Use Infrastructure as Code (Terraform)
- Enable monitoring and observability
- Apply cost optimization practices

---

## 🏗️ Architecture

The system is designed with security and scalability in mind:

- VPC with public and private subnets
- Application Load Balancer (public)
- EC2 instances (private, multi-AZ)
- NAT Gateway for outbound internet access
- CloudWatch for monitoring
- AWS Secrets Manager for secure configuration
- AWS Budgets for cost tracking

### 🔁 Traffic Flow

Internet
↓
Application Load Balancer (Public Subnet)
↓
Target Group
↓
EC2 Instances (Private Subnets - Multi AZ)
↓
CloudWatch Monitoring


---

## 🔐 Security Design

- EC2 instances are not publicly accessible
- Only ALB is exposed to the internet
- Security Groups follow least privilege principle
- IAM Role used instead of hardcoded credentials
- Secrets stored in AWS Secrets Manager

---

## ⚙️ Technologies Used

- AWS (EC2, VPC, ALB, CloudWatch, IAM, Secrets Manager, Budgets)
- Terraform (Infrastructure as Code)
- Node.js (simple application layer)
- GitHub Actions (CI/CD - in progress)

---

## 🖥️ Application

A simple Node.js app that:
- Returns instance metadata (hostname, AZ)
- Exposes a `/health` endpoint for load balancer checks

---

## 📊 Monitoring & Observability

Implemented using CloudWatch:

- Dashboard with:
  - EC2 CPU utilization
  - ALB target health
  - Request count
- 3 Alerts:
  - High CPU usage
  - Unhealthy targets
  - HTTP 5xx errors

---

## 💰 Cost Optimization

- t2.micro instances (low cost)
- Budget alerts configured ($10/month)
- Resource tagging applied

---

## ⚠️ Challenges & Lessons Learned

### Key Challenges:
- Terraform interpolation errors in user_data
- Duplicate resource definitions
- ALB unhealthy targets
- AWS resource conflicts due to state mismatch

### What I Learned:
- Debugging across infrastructure and application layers
- Managing Terraform state effectively
- Designing secure cloud architectures
- Understanding real-world trade-offs (cost vs performance vs security)

---

## 🔄 Future Improvements

- Auto Scaling Groups
- RDS integration
- Full CI/CD pipeline (GitHub Actions)
- Containerization with Docker

---

## 📸 Screenshots

- CloudWatch Dashboard  
- ALB Target Health  
- AWS Secrets Manager  
- Budget Alerts  
- GitHub Actions Pipeline  

---

## 🎬 Demo

Live demo shows:
- Load balancing across multiple instances
- CloudWatch metrics in real time
- Secure secret retrieval

---

## 🙌 Final Thoughts

This project helped me transition from learning concepts to thinking like a cloud engineer.

It was not just about deploying infrastructure, but about:
- Debugging real-world issues
- Making design decisions
- Understanding system behavior

