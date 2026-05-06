provider "aws" {
  region = "eu-west-1"   # Change if you want another region
}

# ✅ Always fetch the latest Ubuntu 20.04 AMI for your region
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

# ✅ Get valid availability zones dynamically
data "aws_availability_zones" "available" {}

# ✅ Security group to allow HTTP + SSH
resource "aws_security_group" "portfolio_sg" {
  name        = "portfolio-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# ✅ EC2 instance
resource "aws_instance" "portfolio" {
  ami           = data.aws_ssm_parameter.ubuntu.value
  instance_type = "t3.micro"              # Free Tier eligible
  key_name      = "key"                # Must match your AWS key pair name
  security_groups = [aws_security_group.portfolio_sg.name]

  tags = {
    Name = "PortfolioApp"
  }
}

# ✅ Classic Load Balancer
resource "aws_elb" "portfolio_lb" {
  name               = "portfolio-lb"
  availability_zones = data.aws_availability_zones.available.names

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances = [aws_instance.portfolio.id]
}

# ✅ Output DNS name of Load Balancer
output "elb_dns_name" {
  value = aws_elb.portfolio_lb.dns_name
}
