terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC i podsieci
resource "aws_vpc" "llm_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "llm-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.llm_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "llm-public-subnet-${count.index}"
  }
}

# Grupa bezpieczeństwa
resource "aws_security_group" "llm_sg" {
  name        = "llm-security-group"
  description = "Security group for LLM services"
  vpc_id      = aws_vpc.llm_vpc.id
  
  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Traefik Dashboard
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Wyjście
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "llm-security-group"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "llm_cluster" {
  name = "llm-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Name = "llm-cluster"
  }
}

# ECR Repositories
resource "aws_ecr_repository" "model_service" {
  name                 = "llm-model-service"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "llm-model-service"
  }
}

resource "aws_ecr_repository" "api_gateway" {
  name                 = "llm-api-gateway"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Name = "llm-api-gateway"
  }
}

# EFS dla przechowywania modeli
resource "aws_efs_file_system" "model_storage" {
  creation_token = "llm-model-storage"
  
  tags = {
    Name = "llm-model-storage"
  }
}

resource "aws_efs_mount_target" "model_storage_mount" {
  count           = 2
  file_system_id  = aws_efs_file_system.model_storage.id
  subnet_id       = aws_subnet.public_subnet[count.index].id
  security_groups = [aws_security_group.llm_sg.id]
}

# Load Balancer
resource "aws_lb" "llm_lb" {
  name               = "llm-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.llm_sg.id]
  subnets            = aws_subnet.public_subnet[*].id
  
  tags = {
    Name = "llm-load-balancer"
  }
}

resource "aws_lb_target_group" "api_gateway" {
  name     = "llm-api-gateway-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.llm_vpc.id
  
  health_check {
    path                = "/ping"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
  
  tags = {
    Name = "llm-api-gateway-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.llm_lb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "llm-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "api-gateway"
      image     = "${aws_ecr_repository.api_gateway.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/llm-api-gateway"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  tags = {
    Name = "llm-api-gateway-task"
  }
}

resource "aws_ecs_task_definition" "model_service" {
  family                   = "llm-model-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "model-service"
      image     = "${aws_ecr_repository.model_service.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "MODEL_PATH"
          value = "/app/models/tinyllama"
        },
        {
          name  = "USE_INT8"
          value = "true"
        },
        {
          name  = "MODEL_SERVICE_PORT"
          value = "5000"
        }
      ]
      
      mountPoints = [
        {
          sourceVolume  = "model-data"
          containerPath = "/app/models"
          readOnly      = false
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/llm-model-service"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  volume {
    name = "model-data"
    
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.model_storage.id
      root_directory = "/"
    }
  }
  
  tags = {
    Name = "llm-model-service-task"
  }
}

# ECS Services
resource "aws_ecs_service" "api_gateway" {
  name            = "llm-api-gateway"
  cluster         = aws_ecs_cluster.llm_cluster.id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = aws_subnet.public_subnet[*].id
    security_groups  = [aws_security_group.llm_sg.id]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.api_gateway.arn
    container_name   = "api-gateway"
    container_port   = 80
  }
  
  depends_on = [aws_lb_listener.http]
  
  tags = {
    Name = "llm-api-gateway-service"
  }
}

resource "aws_ecs_service" "model_service" {
  name            = "llm-model-service"
  cluster         = aws_ecs_cluster.llm_cluster.id
  task_definition = aws_ecs_task_definition.model_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = aws_subnet.public_subnet[*].id
    security_groups  = [aws_security_group.llm_sg.id]
    assign_public_ip = true
  }
  
  tags = {
    Name = "llm-model-service"
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_execution_role" {
  name = "llm-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "llm-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "llm-ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "llm-ecs-task-role"
  }
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/ecs/llm-api-gateway"
  retention_in_days = 30
  
  tags = {
    Name = "llm-api-gateway-logs"
  }
}

resource "aws_cloudwatch_log_group" "model_service" {
  name              = "/ecs/llm-model-service"
  retention_in_days = 30
  
  tags = {
    Name = "llm-model-service-logs"
  }
}
