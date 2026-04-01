data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket_name
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-1"
    Tier = "public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-2"
    Tier = "public"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-1"
    Tier = "private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-2"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nodejs git

              mkdir -p /home/ec2-user/app
              cd /home/ec2-user/app

              cat > server.js <<'EONODE'
              const express = require('express');
              const os = require('os');
              const app = express();

              const PORT = 3000;
              const hostname = os.hostname();
              const availabilityZone = process.env.AZ || "unknown";

              app.get('/', (req, res) => {
                res.send(`
                  <h1>Cloud Capstone App</h1>
                  <p><strong>Hostname:</strong> $${hostname}</p>
                  <p><strong>Availability Zone:</strong> $${availabilityZone}</p>
                  <p><strong>Status:</strong> Running</p>
                `);
              });

              app.get('/health', (req, res) => {
                res.json({ status: "ok" });
              });

              app.get('/info', (req, res) => {
                res.json({
                  hostname,
                  availabilityZone,
                  status: "running"
                });
              });

              app.listen(PORT, '0.0.0.0', () => {
                console.log(`Server running on port $${PORT}`);
              });
              EONODE

              cat > package.json <<'EOPKG'
              {
                "name": "capstone-app",
                "version": "1.0.0",
                "main": "server.js",
                "scripts": {
                  "start": "node server.js"
                },
                "dependencies": {
                  "express": "^4.18.2"
                }
              }
              EOPKG

              npm install

              cat > /etc/systemd/system/capstone-app.service <<'EOSVC'
              [Unit]
              Description=Capstone Node.js App
              After=network.target

              [Service]
              ExecStart=/usr/bin/node /home/ec2-user/app/server.js
              WorkingDirectory=/home/ec2-user/app
              Restart=always
              User=root
              Environment=AZ=${data.aws_availability_zones.available.names[0]}

              [Install]
              WantedBy=multi-user.target
              EOSVC

              systemctl daemon-reload
              systemctl enable capstone-app
              systemctl start capstone-app
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-1"
  }
}

resource "aws_instance" "app_2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nodejs git

              mkdir -p /home/ec2-user/app
              cd /home/ec2-user/app

              cat > server.js <<'EONODE'
              const express = require('express');
              const os = require('os');
              const app = express();

              const PORT = 3000;
              const hostname = os.hostname();
              const availabilityZone = process.env.AZ || "unknown";

              app.get('/', (req, res) => {
                res.send(`
                  <h1>Cloud Capstone App</h1>
                  <p><strong>Hostname:</strong> $${hostname}</p>
                  <p><strong>Availability Zone:</strong> $${availabilityZone}</p>
                  <p><strong>Status:</strong> Running</p>
                `);
              });

              app.get('/health', (req, res) => {
                res.json({ status: "ok" });
              });

              app.get('/info', (req, res) => {
                res.json({
                  hostname,
                  availabilityZone,
                  status: "running"
                });
              });

              app.listen(PORT, '0.0.0.0', () => {
                console.log(`Server running on port $${PORT}`);
              });
              EONODE

              cat > package.json <<'EOPKG'
              {
                "name": "capstone-app",
                "version": "1.0.0",
                "main": "server.js",
                "scripts": {
                  "start": "node server.js"
                },
                "dependencies": {
                  "express": "^4.18.2"
                }
              }
              EOPKG

              npm install

              cat > /etc/systemd/system/capstone-app.service <<'EOSVC'
              [Unit]
              Description=Capstone Node.js App
              After=network.target

              [Service]
              ExecStart=/usr/bin/node /home/ec2-user/app/server.js
              WorkingDirectory=/home/ec2-user/app
              Restart=always
              User=root
              Environment=AZ=${data.aws_availability_zones.available.names[1]}

              [Install]
              WantedBy=multi-user.target
              EOSVC

              systemctl daemon-reload
              systemctl enable capstone-app
              systemctl start capstone-app
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-2"
  }
}

resource "aws_instance" "app_3" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nodejs git

              mkdir -p /home/ec2-user/app
              cd /home/ec2-user/app

              cat > server.js <<'EONODE'
              const express = require('express');
              const os = require('os');
              const app = express();

              const PORT = 3000;
              const hostname = os.hostname();
              const availabilityZone = process.env.AZ || "unknown";

              app.get('/', (req, res) => {
                res.send(`
                  <h1>Cloud Capstone App</h1>
                  <p><strong>Hostname:</strong> $${hostname}</p>
                  <p><strong>Availability Zone:</strong> $${availabilityZone}</p>
                  <p><strong>Status:</strong> Running</p>
                `);
              });

              app.get('/health', (req, res) => {
                res.json({ status: "ok" });
              });

              app.get('/info', (req, res) => {
                res.json({
                  hostname,
                  availabilityZone,
                  status: "running"
                });
              });

              app.listen(PORT, '0.0.0.0', () => {
                console.log(`Server running on port $${PORT}`);
              });
              EONODE

              cat > package.json <<'EOPKG'
              {
                "name": "capstone-app",
                "version": "1.0.0",
                "main": "server.js",
                "scripts": {
                  "start": "node server.js"
                },
                "dependencies": {
                  "express": "^4.18.2"
                }
              }
              EOPKG

              npm install

              cat > /etc/systemd/system/capstone-app.service <<'EOSVC'
              [Unit]
              Description=Capstone Node.js App
              After=network.target

              [Service]
              ExecStart=/usr/bin/node /home/ec2-user/app/server.js
              WorkingDirectory=/home/ec2-user/app
              Restart=always
              User=root
              Environment=AZ=${data.aws_availability_zones.available.names[0]}

              [Install]
              WantedBy=multi-user.target
              EOSVC

              systemctl daemon-reload
              systemctl enable capstone-app
              systemctl start capstone-app
              EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-app-3"
  }
}
resource "aws_lb" "app_alb" {
  name               = "capstone-dev-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "capstone-dev-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "3000"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

resource "aws_lb_target_group_attachment" "app_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_1.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "app_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_2.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "app_3" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_3.id
  port             = 3000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app_1.id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app_2.id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.app_3.id]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.app_tg.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.app_tg.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Target Health"
        }
      }
    ]
  })
}
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    InstanceId = aws_instance.app_1.id
  }

  alarm_description = "CPU usage too high"
}
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  alarm_description = "ALB has unhealthy targets"
}
resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.project_name}-${var.environment}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1

  dimensions = {
    InstanceId = aws_instance.app_1.id
  }

  alarm_description = "EC2 instance status check failed"
}

