# Prefect Worker on Amazon ECS Fargate

## Purpose
This project deploys a Prefect worker on Amazon ECS Fargate using Terraform to execute workflows orchestrated by Prefect Cloud. The setup includes a VPC, subnets, NAT gateway, ECS cluster, IAM roles, and Secrets Manager for secure API key storage.

## IaC Tool Choice
**Terraform** was chosen for its:
- **Cross-cloud flexibility**: Works with AWS and other providers, making it versatile for learning.
- **Open-source community**: Large ecosystem with reusable modules.
- **HCL syntax**: Clear and modular for defining infrastructure.

## Prerequisites
- AWS account with permissions to create VPC, ECS, IAM, and Secrets Manager resources.
- Terraform >= 1.2.0 installed.
- AWS CLI configured with credentials.
- Prefect Cloud account with API key, Account ID, Workspace ID, and `ecs-work-pool` created.
- Docker (optional, for local testing).

## Deployment Instructions
1. **Clone the Repository**:
   ```bash
   git clone <your-repo-url>
   cd prefect-ecs-assignment