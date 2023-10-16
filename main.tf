provider "aws" {
  region = var.region
}

//backend
terraform {
  backend "s3" {
    bucket = "demo-autoscaling-monitor-state"
    key = "global/s3/terraform.tfstate"
    region = "ap-southeast-1"

    dynamodb_table = "demo-autoscaling-monitor-locks"
    encrypt = true
  }
}

data "aws_ami" "amazon-linux-2" {
    most_recent = true

    filter {
        name   = "owner-alias"
        values = ["amazon"]
    }

    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

resource "aws_launch_template" "example" {
  #  image_id             = "ami-0db1894e055420bc0"
  image_id               = "ami-0a07a2c738f040240"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = "Son-SG"

  user_data = filebase64("user_data.sh")

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks  = ["42.112.15.4/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

//todo: create vpc - subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

//todo: move elb to public subnet and ec2 to private subnet
resource "aws_lb" "example" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
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

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "example" {
  name_prefix = "demo-"
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"

  enabled_metrics = [
    "GroupInServiceInstances"
  ]

  launch_template {
    id      = aws_launch_template.example.id
    version = aws_launch_template.example.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      #instance_warmup = 300 # Default behavior is to use the Auto Scaling Group's health check grace period.
      min_healthy_percentage = 50
    }
    triggers = [ /*"launch_template",*/ "desired_capacity" ] # You can add any argument from ASG here, if those has changes, ASG Instance Refresh will trigger
  }

  desired_capacity = 2
  min_size = 2
  max_size = 5

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

//todo: disable scale-in and create separate scale-in policy
//todo: create cloudwatch alarm CPU75, CPU50 and scale-in
resource "aws_autoscaling_policy" "avg-cpu-policy-maintain-at-xx" {
  autoscaling_group_name    = aws_autoscaling_group.example.id
  name                      = "avg-cpu-policy-maintain-at-xx"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 180 # defaults to ASG default cooldown 300 seconds if not set

  target_tracking_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
#    disable_scale_in = true
  }
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
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

//dashboard
resource "aws_cloudwatch_dashboard" "monitor-ASG" {
  dashboard_name = "monitor-ASG"

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
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              aws_autoscaling_group.example.id
            ]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ASG Average CPUUtilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              aws_autoscaling_group.example.id
            ]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ASG Average Instances"
        }
      }
    ]
  })
}