resource "aws_security_group" "lb_sg" {
  provider    = aws.region_master
  name        = "lb_sg"
  description = "Allow 443 and traffic to Jenkins SG"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere for redirection"
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


resource "aws_security_group" "jenkins_sg" {
  provider    = aws.region_master
  name        = "jenkins_sg"
  description = "Allow TCP/8080, TCP/22 and traffic from peering VPC"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description     = "Allow TCP/8080 from anywhere"
    from_port       = var.web_server_port
    to_port         = var.web_server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    description = "Allow TCP/22 from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_sg_oregon" {
  provider    = aws.region_worker
  name        = "jenkins_sg_oregon"
  description = "Allow TCP/22 and traffic from peering VPC"
  vpc_id      = aws_vpc.vpc_worker.id
  ingress {
    description = "Allow TCP/22 from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}