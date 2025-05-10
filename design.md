# Design Document: Prefect Worker on Amazon ECS Fargate

This document provides the High-Level Design (HLD) and Low-Level Design (LLD) for deploying a Prefect worker on Amazon ECS Fargate using Terraform, as part of the DevOps Intern assignment for AI Planet. The setup includes a VPC, ECS cluster, IAM roles, Secrets Manager, and networking components, connected to a Prefect Cloud work pool.

## High-Level Design (HLD)

### Overview
The system deploys a Prefect worker on AWS ECS Fargate to execute workflows orchestrated by Prefect Cloud. The infrastructure is defined using Terraform for Infrastructure as Code (IaC), ensuring repeatability and scalability. Key components include:
- **VPC**: A virtual network with public and private subnets for secure resource placement.
- **ECS Cluster**: A managed container orchestration service running the Prefect worker on Fargate.
- **IAM Roles**: Permissions for ECS tasks to access Secrets Manager and execute workflows.
- **Secrets Manager**: Stores the Prefect API key securely.
- **Prefect Cloud**: Orchestrates workflows and communicates with the worker via a work pool.
- **Networking**: NAT Gateway and route tables enable outbound internet access for private subnets.

### Architecture Diagram
Below is a high-level architecture diagram illustrating component interactions:

**Flow**:
1. Prefect Cloud sends workflow tasks to the `ecs-work-pool`.
2. The Prefect worker (`dev-worker`) in the ECS cluster pulls tasks via HTTPS, using the API key from Secrets Manager.
3. The worker runs tasks in a Fargate container, logging output to CloudWatch.
4. Private subnets ensure secure task execution, with outbound internet access via the NAT Gateway.

### Design Goals
- **Security**: Use IAM roles and Secrets Manager to manage credentials securely.
- **Scalability**: Fargate allows serverless scaling of worker tasks.
- **Maintainability**: Terraform enables consistent infrastructure provisioning.
- **Cost Efficiency**: Single NAT Gateway minimizes costs while meeting requirements.

## Low-Level Design (LLD)

### 1. VPC and Networking
- **VPC**:
  - Resource: `aws_vpc.prefect_vpc`
  - CIDR Block: `10.0.0.0/16`
  - DNS Hostnames: Enabled
  - Tags: `Name = prefect-ecs`
- **Subnets**:
  - **Public Subnets** (3):
    - Resources: `aws_subnet.public`
    - CIDR Blocks: `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`
    - Availability Zones: Spread across 3 AZs (e.g., `us-east-1a`, `us-east-1b`, `us-east-1c`)
    - Map Public IP: Enabled
    - Tags: `Name = prefect-ecs-public-<index>`
  - **Private Subnets** (3):
    - Resources: `aws_subnet.private`
    - CIDR Blocks: `10.0.4.0/24`, `10.0.5.0/24`, `10.0.6.0/24`
    - Availability Zones: Same as public subnets
    - Map Public IP: Disabled
    - Tags: `Name = prefect-ecs-private-<index>`
- **Internet Gateway**:
  - Resource: `aws_internet_gateway.igw`
  - Attached to VPC
  - Tags: `Name = prefect-ecs`
- **NAT Gateway**:
  - Resource: `aws_nat_gateway.nat`
  - Deployed in first public subnet (`10.0.1.0/24`)
  - Elastic IP: `aws_eip.nat`
  - Tags: `Name = prefect-ecs`
- **Route Tables**:
  - **Public Route Table**:
    - Resource: `aws_route_table.public`
    - Route: `0.0.0.0/0` to Internet Gateway
    - Associated with public subnets
    - Tags: `Name = prefect-ecs-public`
  - **Private Route Table**:
    - Resource: `aws_route_table.private`
    - Route: `0.0.0.0/0` to NAT Gateway
    - Associated with private subnets
    - Tags: `Name = prefect-ecs-private`

### 2. ECS Cluster
- **Cluster**:
  - Resource: `aws_ecs_cluster.prefect_cluster`
  - Name: `prefect-cluster`
  - Tags: `Name = prefect-ecs`
- **Service Discovery**:
  - Resource: `aws_service_discovery_private_dns_namespace.prefect_dns`
  - Namespace: `default.prefect.local`
  - VPC: Attached to `prefect_vpc`

### 3. IAM Roles
- **Task Execution Role**:
  - Resource: `aws_iam_role.ecs_task_execution_role`
  - Name: `prefect-task-execution-role`
  - Trust Policy: Allows `ecs-tasks.amazonaws.com` to assume the role
  - Policies:
    - `AmazonECSTaskExecutionRolePolicy` (AWS-managed)
    - Custom Policy (`aws_iam_policy.secrets_access`):
      - Actions: `secretsmanager:GetSecretValue`, `secretsmanager:DescribeSecret`
      - Resource: `prefect-api-key` ARN
  - Tags: `Name = prefect-ecs`

### 4. Secrets Manager
- **Secret**:
  - Resource: `aws_secretsmanager_secret.prefect_api_key`
  - Name: `prefect-api-key`
  - Stores: Prefect Cloud API key (provided in `terraform.tfvars`)
  - Version: `aws_secretsmanager_secret_version.prefect_api_key_version`
  - Tags: `Name = prefect-ecs`

### 5. Prefect Worker
- **Task Definition**:
  - Resource: `aws_ecs_task_definition.prefect_worker`
  - Family: `prefect-worker-task`
  - Network Mode: `awsvpc`
  - Launch Type: `FARGATE`
  - CPU: 512
  - Memory: 1024
  - Execution Role: `prefect-task-execution-role`
  - Task Role: `prefect-task-execution-role`
  - Container Definition:
    - Name: `prefect-worker`
    - Image: `prefecthq/prefect:2-latest`
    - CPU: 512
    - Memory: 1024
    - Command: `/bin/sh -c "pip install prefect-aws && prefect worker start --pool ecs-work-pool --type ecs"`
    - Environment Variables:
      - `PREFECT_API_URL`: `https://api.prefect.cloud/api`
      - `PREFECT_ACCOUNT_ID`: From `terraform.tfvars`
      - `PREFECT_WORKSPACE_ID`: From `terraform.tfvars`
    - Secrets:
      - `PREFECT_API_KEY`: Fetched from `prefect-api-key` in Secrets Manager
    - Logging:
      - Log Driver: `awslogs`
      - Log Group: `/ecs/prefect-worker`
      - Region: `us-east-1`
      - Stream Prefix: `prefect`
- **Service**:
  - Resource: `aws_ecs_service.prefect_worker_service`
  - Name: `dev-worker`
  - Cluster: `prefect-cluster`
  - Task Definition: `prefect-worker-task`
  - Launch Type: `FARGATE`
  - Desired Count: 1
  - Network Configuration:
    - Subnets: Private subnets (`10.0.4.0/24`, `10.0.5.0/24`, `10.0.6.0/24`)
    - Security Group: `aws_security_group.ecs_service_sg` (allows all outbound traffic)
    - Assign Public IP: Disabled
  - Tags: `Name = prefect-ecs`
- **Security Group**:
  - Resource: `aws_security_group.ecs_service_sg`
  - Name: `prefect-ecs-service-sg`
  - VPC: `prefect_vpc`
  - Egress: Allow all outbound traffic (`0.0.0.0/0`)
  - Tags: `Name = prefect-ecs`
- **Log Group**:
  - Resource: `aws_cloudwatch_log_group.prefect_worker_logs`
  - Name: `/ecs/prefect-worker`
  - Tags: `Name = prefect-ecs`

### 6. Outputs
- **ECS Cluster ARN**:
  - Resource: `output.ecs_cluster_arn`
  - Value: ARN of `prefect-cluster`
  - Description: Used to reference the cluster in AWS Console or CLI.

## Design Considerations
- **Security**:
  - The Prefect API key is stored in Secrets Manager, not hardcoded, to prevent exposure.
  - The ECS service runs in private subnets, inaccessible from the public internet.
  - IAM roles follow the principle of least privilege.
- **Cost**:
  - A single NAT Gateway reduces costs compared to one per AZ, sufficient for this setup.
  - Fargate’s serverless model avoids EC2 management overhead.
- **Reliability**:
  - Subnets span multiple AZs for high availability.
  - Service discovery (`default.prefect.local`) enables internal DNS resolution.
- **Maintainability**:
  - Terraform variables (`variables.tf`) allow easy configuration changes.
  - Tags (`Name = prefect-ecs`) simplify resource identification.

## Challenges Addressed
- **Duplicate Secret Error**: Ensured `PREFECT_API_KEY` is only defined as a secret, not an environment variable, in the task definition.
- **Git Large File Issue**: Excluded `.terraform` directory using `.gitignore` to comply with GitHub’s 100 MB limit.

## Future Improvements
- **Auto-Scaling**: Configure ECS service auto-scaling based on CPU/memory metrics.
- **Monitoring**: Add CloudWatch alarms for task failures or high resource usage.
- **CI/CD**: Use AWS CodePipeline to automate Terraform deployments.
- **Cost Optimization**: Explore AWS Savings Plans or Spot Instances for non-critical workloads.

## References
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws
- AWS ECS Fargate: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
- Prefect ECS Worker: https://docs.prefect.io/latest/integrations/prefect-aws/ecs-worker/