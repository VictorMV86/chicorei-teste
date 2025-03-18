resource "aws_default_vpc" "chicorei_vpc" {
    tags = {
        Name = "Default VPC"
    }
}

resource "aws_key_pair" "chicorei-key" {
  key_name   = "chicorei-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTTvG/7ldjFgyfwXF3EhYy21YQpuMmIVOSDE1xI4VG9 melo.victor86@gmail.com"
}

resource "aws_instance" "chico_rei_ec2" {
  ami           = "ami-04d88e4b4e0a5db46" 
  instance_type = var.instance_type
  count         = 2
  key_name      = aws_key_pair.chicorei-key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  user_data = file("user_data.sh")

  vpc_security_group_ids = [aws_security_group.ec2_sg.id,aws_security_group.allow_ssh_sg.id]

  tags = {
    Name = "instance-${count.index}"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
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

resource "aws_security_group" "allow_ssh_sg" {
  name        = "allow_ssh-security-group"
  description = "Allow SSH and HTTP inbound traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_subnet" "example1" {
  vpc_id = aws_default_vpc.chicorei_vpc.id
  cidr_block        = "172.31.48.0/20"
  availability_zone = "sa-east-1b"
  tags = {
    Name = "example-subnet-1"
  }
   }

resource "aws_subnet" "example2" {
  vpc_id = aws_default_vpc.chicorei_vpc.id
  cidr_block        = "172.30.1.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name = "example-subnet-2"
    }
  }

resource "aws_lb" "chicorei-lb" {
  name               = "chicorei-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = [aws_subnet.example1.id, aws_subnet.example2.id]

  access_logs {
    bucket  = aws_s3_bucket.chicorei_s3.id
    prefix  = "chicorei-lb"
    enabled = true
  }
}

resource "aws_lb_target_group" "target-group" {
    health_check {
        interval            = 10
        path                = "/"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
    }
    name          = "chicorei-tg"
    port          = 80
    protocol      = "HTTP"
    target_type   = "instance"
    vpc_id = aws_default_vpc.chicorei_vpc.id
}

resource "aws_lb_target_group_attachment" "ec2_attach" {
    count = length(aws_instance.chico_rei_ec2)
    target_group_arn = aws_lb_target_group.target-group.arn
    target_id        = aws_instance.chico_rei_ec2[count.index].id
}

resource "aws_db_instance" "chicoreidb" {
  allocated_storage    = 10 
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = "chicoreidb"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true 

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "example-rds-instance"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow MySQL inbound traffic from EC2"

  ingress {
    from_port   = 3306
    to_port     = 3306
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


resource "aws_s3_bucket" "chicorei_s3" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "var.s3_bucket_name"
  }
}

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2_cloudwatch_role"

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

# Attach the CloudWatch agent policy to the IAM role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create an IAM instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2_cloudwatch_profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}
