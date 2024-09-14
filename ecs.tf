provider "aws" {
  region = "us-east-1"  # Specify your desired region
}

# Create a VPC
resource "aws_vpc" "fastapi_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create Subnets
resource "aws_subnet" "fastapi_subnet" {
  vpc_id     = aws_vpc.fastapi_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "fastapi_igw" {
  vpc_id = aws_vpc.fastapi_vpc.id
}

# Create a Route Table and associate with Subnet
resource "aws_route_table" "fastapi_route_table" {
  vpc_id = aws_vpc.fastapi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fastapi_igw.id
  }
}

resource "aws_route_table_association" "fastapi_route_assoc" {
  subnet_id      = aws_subnet.fastapi_subnet.id
  route_table_id = aws_route_table.fastapi_route_table.id
}

# Create ECS cluster
resource "aws_ecs_cluster" "fastapi_cluster" {
  name = "fastapi-cluster"
}

# Create ECS Task Definition
resource "aws_ecs_task_definition" "fastapi_task" {
  family                   = "fastapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "fastapi-container",
      image     = "<YOUR_DOCKER_IMAGE>",
      cpu       = 256,
      memory    = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])
}

# Create ECS Service
resource "aws_ecs_service" "fastapi_service" {
  name            = "fastapi-service"
  cluster         = aws_ecs_cluster.fastapi_cluster.id
  task_definition = aws_ecs_task_definition.fastapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets         = [aws_subnet.fastapi_subnet.id]
    assign_public_ip = true
  }
}

# Create a Security Group for ECS
resource "aws_security_group" "fastapi_sg" {
  vpc_id = aws_vpc.fastapi_vpc.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an IAM role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

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
}

# Attach the necessary policy to the role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
