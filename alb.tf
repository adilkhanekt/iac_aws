resource "aws_lb" "alb" {
  provider           = aws.region_master
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  tags = {
    Name = "Jenkins_LB"
  }
}

resource "aws_lb_target_group" "alb_target" {
  provider    = aws.region_master
  name        = "target"
  port        = var.web_server_port
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_master.id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10
    path     = "/login"
    port     = var.web_server_port
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "Jenkins_target_group"
  }
}

resource "aws_lb_target_group_attachment" "alb_target_attachment" {
  provider         = aws.region_master
  target_group_arn = aws_lb_target_group.alb_target.arn
  target_id        = aws_instance.jenkins_master.id
  port             = var.web_server_port
}

resource "aws_lb_listener" "alb_listener" {
  provider          = aws.region_master
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "alb_listener_https" {
  provider          = aws.region_master
  load_balancer_arn = aws_lb.alb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}