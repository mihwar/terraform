terraform {
  backend "s3" {
    bucket = "terraform-unr-state"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

resource "aws_launch_configuration" "example" {
  image_id 	= "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.alb.id]
  user_data = <<-EOF
	      #!/bin/bash
              echo "Hello, World!!!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.MihWar.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
    key 		= "Name"
    value 		= "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example" {
  name 			= "terraform-asg-example"
  load_balancer_type 	= "application"
  subnets		= data.aws_subnet_ids.MihWar.ids
  security_groups	= [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn 	= aws_lb.example.arn
  port			= 80
  protocol		= "HTTP"

  # По умолчанию возвращает простую страницу с кодом 404
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

    # Разрешаем все входящие HTTP-запросы
  ingress {
    from_port		= var.server_port
    to_port		= var.server_port
    protocol		= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }

   # Разрешаем все исходящие запросы
  egress {
    from_port		= 0
    to_port		= 0
    protocol		= "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }

}
  
resource "aws_lb_target_group" "asg" {
  name 	= "terraform-asg-example"
  port 	= var.server_port
  protocol 	= "HTTP"
  vpc_id 	= data.aws_vpc.MihWar.id

  health_check {
    path 	= "/"
    protocol 	= "HTTP"
    matcher 	= "200"
    interval	= 15
    timeout	= 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
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
    type 		= "forward"
    target_group_arn 	= aws_lb_target_group.asg.arn
  }
}

output "alb_dns_name" {
  value 	= aws_lb.example.dns_name
  description 	= "The domain name of the load balancer"
}

data "aws_vpc" "MihWar" {
  default = true
}
data "aws_subnet_ids" "MihWar" {
  vpc_id = data.aws_vpc.MihWar.id
}
