provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_configuration" "example" {
  image_id 	= "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]
  user_data = <<-EOF
	      #!/bin/bash
              echo "Hello, World!!!" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
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
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}


resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.MihWar.ids

  min_size = 2
  max_size = 3

  tag {
    key 		= "Name"
    value 		= "terraform-asg-example"
    propagate_at_launch = true
  }
}

data "aws_vpc" "MihWar" {
  default = true
}
data "aws_subnet_ids" "MihWar" {
  vpc_id = data.aws_vpc.MihWar.id
}
