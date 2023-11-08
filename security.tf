resource "aws_security_group" "sg_ec2" {
  name   = "${var.PROJECT_NAME}-sg_ec2"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # cidr_blocks = ["42.112.15.4/32"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "sg_alb" {
  name   = "${var.PROJECT_NAME}-sg_alb"
  vpc_id = aws_vpc.vpc.id

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
