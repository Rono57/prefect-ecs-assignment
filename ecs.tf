resource "aws_ecs_cluster" "prefect_cluster" {
  name = "prefect-cluster"
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_service_discovery_private_dns_namespace" "prefect_dns" {
  name        = "default.prefect.local"
  vpc         = aws_vpc.prefect_vpc.id
  description = "Private DNS for Prefect worker"
}

resource "aws_security_group" "ecs_service_sg" {
  vpc_id = aws_vpc.prefect_vpc.id
  name   = "prefect-ecs-service-sg"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_ecs_task_definition" "prefect_worker" {
  family                   = "prefect-worker-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "prefect-worker"
      image = "prefecthq/prefect:2-latest"
      cpu   = 512
      memory = 1024
      essential = true
      command = [
        "/bin/sh",
        "-c",
        "pip install prefect-aws && prefect worker start --pool ecs-work-pool --type ecs"
      ]
      environment = [
        { name = "PREFECT_API_URL", value = var.prefect_api_url },
    
        { name = "PREFECT_ACCOUNT_ID", value = var.prefect_account_id },
        { name = "PREFECT_WORKSPACE_ID", value = var.prefect_workspace_id }
      ]
      secrets = [
        {
          name      = "PREFECT_API_KEY"
          valueFrom = aws_secretsmanager_secret.prefect_api_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/prefect-worker"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "prefect"
        }
      }
    }
  ])
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_cloudwatch_log_group" "prefect_worker_logs" {
  name = "/ecs/prefect-worker"
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_ecs_service" "prefect_worker_service" {
  name            = "dev-worker"
  cluster         = aws_ecs_cluster.prefect_cluster.id
  task_definition = aws_ecs_task_definition.prefect_worker.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }
  tags = {
    Name = "prefect-ecs"
  }
}