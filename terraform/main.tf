# RDS MySQL Database

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = var.vpc_id
  availability_zone       = "us-east-1b"
  cidr_block              = "172.31.16.0/20"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = var.vpc_id
  availability_zone       = "us-east-1c"
  cidr_block              = "172.31.32.0/20"
  map_public_ip_on_launch = false
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Security group for RDS MySQL"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service_security_group.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "mysql_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.mysql_sg.id
  security_group_id        = aws_security_group.ecs_service_security_group.id
}

data "aws_vpc" "main_vpc" {
  id = var.vpc_id
}

resource "aws_db_parameter_group" "mysql_parameter_group" {
  name        = "mysql-parameter-group"
  family      = "mysql5.7"
  description = "Custom DB parameter group for MySQL 5.7"
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS DB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql_instance" {
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.username
  password             = var.password
  parameter_group_name = aws_db_parameter_group.mysql_parameter_group.name
  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.rds_security_group.id
  ]
}

# ECS Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "afourathon-cluster"
}

resource "aws_ecs_task_definition" "cab_app_task" {
  family                   = "cab-app"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name": "cab-app",
      "image": "${aws_ecr_repository.cab_app.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "memoryReservation": 512,
      "cpu": 256,
      "environmentFiles": [
        {
          "value": "arn:aws:s3:::afourathon/env_files/.env",
          "type": "s3"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-group": "cab-app-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "cab-app"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "driver_app_task" {
  family                   = "driver-app"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name": "driver-app",
      "image": "${aws_ecr_repository.driver_app.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "memoryReservation": 512,
      "cpu": 256,
      "environmentFiles": [
        {
          "value": "arn:aws:s3:::afourathon/env_files/.env",
          "type": "s3"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-group": "driver-app-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "driver-app"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "cab_assignment_app_task" {
  family                   = "cab-assignment-app"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name": "cab-assignment-app",
      "image": "${aws_ecr_repository.cab_assignment_app.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "memoryReservation": 512,
      "cpu": 256,
      "environmentFiles": [
        {
          "value": "arn:aws:s3:::afourathon/env_files/.env",
          "type": "s3"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-group": "cab-assignment-app-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "cab-assignment-app"
        }
      }
    }
  ])
}

# Create AWS Cloud Map private DNS namespace
resource "aws_service_discovery_private_dns_namespace" "private_dns_namespace" {
  name = "afourathon-private-namespace"
  vpc  = var.vpc_id
}

# Create AWS Cloud Map service for cab app
resource "aws_service_discovery_service" "cab_app_service" {
  name              = "cab-app-service"
  namespace_id      = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

# Create AWS Cloud Map service for driver app
resource "aws_service_discovery_service" "driver_app_service" {
  name              = "driver-app-service"
  namespace_id      = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}
# Create AWS Cloud Map service for cab assignment app
resource "aws_service_discovery_service" "cab_assignment_app_service" {
  name              = "cab-assignment-app-service"
  namespace_id      = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private_dns_namespace.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

# Update web app task definition with environment variables
resource "aws_ecs_task_definition" "web_app_task" {
  family                   = "web-app"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "bridge"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name": "web-app",
      "image": "${aws_ecr_repository.web_app.repository_url}:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "memoryReservation": 512,
      "cpu": 256,
      "environment": [
        {
          "name": "REACT_APP_CAB_API_URL",
          "value": aws_service_discovery_service.cab_app_service.arn
        },
        {
          "name": "REACT_APP_DRIVER_API_URL",
          "value": aws_service_discovery_service.driver_app_service.arn
        },
        {
          "name": "REACT_APP_CAB_ASSIGN_API_URL",
          "value": aws_service_discovery_service.cab_assignment_app_service.arn
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-create-group": "true",
          "awslogs-group": "web-app-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "web-app"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "cab_app_service" {
  name            = "cab-app-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.cab_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.ecs_service_security_group.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "driver_app_service" {
  name            = "driver-app-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.driver_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.ecs_service_security_group.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "cab_assignment_app_service" {
  name            = "cab-assignment-app-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.cab_assignment_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.ecs_service_security_group.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "web_app_service" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.web_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.ecs_service_security_group.id]
    assign_public_ip = true
  }
}

resource "aws_security_group" "ecs_service_security_group" {
  name        = "ecs-service-security-group"
  description = "Security group for ECS Fargate services"

  ingress {
    from_port   = 0
    to_port     = 65535
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

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_s3_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name   = "ecs-task-execution-role-policy"
  role   = aws_iam_role.ecs_task_execution_role.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudWatchLogsPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
POLICY
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = var.vpc_id
  availability_zone       = "us-east-1a"
  cidr_block              = "172.31.80.0/20"
  map_public_ip_on_launch = true
}

resource "aws_ecr_repository" "cab_app" {
  name = "cab-app"
}

resource "aws_ecr_repository" "driver_app" {
  name = "driver-app"
}

resource "aws_ecr_repository" "cab_assignment_app" {
  name = "cab-assignment-app"
}

resource "aws_ecr_repository" "web_app" {
  name = "web-app"
}
