



# DevOps Internship Assignment Report

## Tool Choice: Why Terraform?
I chose **Terraform** over AWS CloudFormation because:
- **Flexibility**: Terraform is cloud-agnostic, allowing me to apply skills to other cloud providers in the future.
- **Community Support**: Its open-source nature provides access to a vast library of modules and community resources, ideal for a beginner.
- **Modular Code**: Terraform’s HCL syntax is intuitive and supports modularization, making the code reusable and maintainable.
While CloudFormation is AWS-native and tightly integrated, Terraform’s versatility and learning potential made it the better choice for this internship task.

## Key Learnings
- **Infrastructure as Code (IaC)**: I learned how IaC automates infrastructure provisioning, ensuring consistency and reducing manual errors. Terraform’s declarative syntax simplified defining complex resources like VPCs and ECS clusters.
- **Amazon ECS Fargate**: I understood ECS as a container orchestration service and Fargate as a serverless compute engine, eliminating the need to manage EC2 instances.
- **Prefect**: I explored Prefect’s worker model, where workers pull tasks from work pools in Prefect Cloud, enabling scalable workflow orchestration.
- **AWS Services**: I gained hands-on experience with VPCs, subnets, NAT gateways, IAM roles, and Secrets Manager, learning their roles in secure and scalable infrastructure.

## Challenges and Resolutions
1. **VPC Networking**:
   - **Challenge**: Configuring public and private subnets with a NAT gateway for outbound traffic was complex, as I was unfamiliar with AWS networking.
   - **Resolution**: I studied AWS VPC documentation and used Terraform’s `aws_vpc` and `aws_nat_gateway` resources, ensuring private subnets accessed the internet via the NAT gateway in a public subnet.
2. **IAM Role Permissions**:
   - **Challenge**: The Prefect worker needed access to Secrets Manager, but I initially missed the trust policy for ECS tasks.
   - **Resolution**: I added a trust policy allowing `ecs-tasks.amazonaws.com` to assume the role and attached a custom policy for Secrets Manager access.
3. **Prefect Worker Connectivity**:
   - **Challenge**: The worker didn’t appear in Prefect Cloud initially.
   - **Resolution**: I verified the API key, Account ID, and Workspace ID in Secrets Manager and ensured the ECS task definition included the correct environment variables.

## Suggestions for Improvement
- **Auto-Scaling**: Configure ECS service auto-scaling based on CPU/memory usage to handle variable workflow loads.
- **Monitoring**: Integrate Amazon CloudWatch for real-time monitoring of ECS tasks and Prefect worker logs.
- **CI/CD Pipeline**: Use AWS CodePipeline to automate Terraform deployments, enabling version-controlled infrastructure updates.
- **Cost Optimization**: Use AWS Budgets to monitor costs and consider Spot Instances for non-critical workloads.

## Demo
A video demo is available at `<link-to-your-demo>` (or describe: “Deployed infrastructure in AWS, verified ECS service running, and confirmed worker active in Prefect Cloud”).

## Conclusion
This assignment was a valuable introduction to DevOps practices, IaC, and cloud orchestration. Despite initial unfamiliarity, I successfully deployed a Prefect worker on ECS Fargate using Terraform, gaining confidence in AWS and Prefect. The challenges taught me to debug systematically and leverage documentation, preparing me for real-world DevOps tasks.