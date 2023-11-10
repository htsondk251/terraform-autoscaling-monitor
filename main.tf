provider "aws" {
  region = var.region
}

//backend
# terraform {
#   backend "s3" {
#     bucket = "demo-autoscaling-monitor-state"
#     key = "global/s3/terraform.tfstate"
#     region = var.region
#     dynamodb_table = "demo-autoscaling-monitor-locks"
#     encrypt        = true
#   }
# }

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "tpl" {
  image_id               = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  key_name               = var.KEY_PAIR

  user_data = filebase64("config.sh")

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "alb" {
  name               = "${var.PROJECT_NAME}-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public-subnet-1a.id, aws_subnet.public-subnet-1b.id]
  security_groups    = [aws_security_group.sg_alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.PROJECT_NAME}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.PROJECT_NAME}-asg"
  vpc_zone_identifier = [aws_subnet.private-subnet-1a.id, aws_subnet.private-subnet-1b.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]
  health_check_type   = "ELB"

  enabled_metrics = [
    "GroupInServiceInstances"
  ]

  launch_template {
    id      = aws_launch_template.tpl.id
    version = aws_launch_template.tpl.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      #instance_warmup = 300 # Default behavior is to use the Auto Scaling Group's health check grace period.
      min_healthy_percentage = 50
    }
    triggers = [/*"launch_template",*/ "desired_capacity"] # You can add any argument from ASG here, if those has changes, ASG Instance Refresh will trigger
  }

  desired_capacity = var.ASG_DESIRED_CAPACITY
  min_size         = var.ASG_MIN_SIZE
  max_size         = var.ASG_MAX_SIZE

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "avg-cpu-policy-maintain-at-xx" {
  autoscaling_group_name    = aws_autoscaling_group.asg.id
  name                      = "avg-cpu-policy-maintain-at-xx"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180 # defaults to ASG default cooldown 300 seconds if not set

  target_tracking_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    disable_scale_in = true
  }
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.PROJECT_NAME}-asg-scale-in"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "${var.PROJECT_NAME}-asg-scale-in-alarm"
  alarm_description   = "asg-scale-in-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5" # Instance will scale in when CPU utilization is lower than 5 %
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_in.arn]
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
