resource "aws_security_group" "jenkins-sg" {
  name        = "jenkins-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }

  tags = {
    Name = "jenkins-sg-dev"
  }

}

resource "aws_security_group" "nexus-sg" {
  name        = "nexus-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }

  ingress {
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    security_groups  = [aws_security_group.jenkins-sg.id]  # Ensure jenkins-sg exists
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }

  tags = {
    Name = "nexus-sg-dev"
  }
}

resource "aws_security_group" "sonarqube-sg" {
  name        = "sonarqube-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }

  tags = {
    Name = "sonarqube-sg-dev"
  }

}

resource "aws_security_group_rule" "jenkins-to-sonarqube-2" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sonarqube-sg.id
  security_group_id        = aws_security_group.jenkins-sg.id

  depends_on = [
    aws_security_group.jenkins-sg,
    aws_security_group.sonarqube-sg
  ]
}

resource "aws_security_group_rule" "sonarqube-to-jenkins-2" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins-sg.id
  security_group_id        = aws_security_group.sonarqube-sg.id

  depends_on = [
    aws_security_group.jenkins-sg,
    aws_security_group.sonarqube-sg
  ]
}

/*
resource "aws_security_group" "git-ec2-sg" {
  name        = "git-ec2-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [ aws_security_group.jenkins-sg.id] 
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # Ensure my_ip is in CIDR format (e.g., 192.168.1.1/32)
  }

  tags = {
    Name = "git-ec2-sg"
  }

}


/*data "aws_ami" "dev-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  tags = {
    Name = "${var.env_prefix}-ami"
  }

}*/

resource "aws_key_pair" "dev-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}






resource "aws_instance" "jenkins" {
  ami                         = "ami-03e31863b8e1f70a5"
  instance_type               = "t2.large"
  availability_zone           = var.availability_zone_1
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  key_name                    = aws_key_pair.dev-key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  
  tags = {
    Name = "jenkins-dev"
  }

}

resource "aws_instance" "nexus-ec2" {
      ami                         = "ami-03e31863b8e1f70a5"
      instance_type               = var.instance_type
      availability_zone           = var.availability_zone_1
      subnet_id                   = var.subnet_id
      vpc_security_group_ids      = [aws_security_group.nexus-sg.id]
      key_name                    = aws_key_pair.dev-key.key_name
      associate_public_ip_address = true
      
      tags = {
        Name = "nexus-dev"
      }

}

resource "aws_instance" "sonarqube-ec2" {
        ami                         = "ami-007868005aea67c54"
        instance_type               = var.instance_type
        availability_zone           = var.availability_zone_1
        subnet_id                   = var.subnet_id
        vpc_security_group_ids      = [aws_security_group.sonarqube-sg.id]
        key_name                    = aws_key_pair.dev-key.key_name
        associate_public_ip_address = true
        
        tags = {
          Name = "sonarqube-dev"
        }

}
/*
resource "aws_instance" "git-ec2" {
        ami                         = "ami-03e31863b8e1f70a5"
        instance_type               = "t2.micro"
        availability_zone           = var.availability_zone_1
        subnet_id                   = var.subnet_id
        vpc_security_group_ids      = [aws_security_group.git-ec2-sg.id]
        key_name                    = aws_key_pair.dev-key.key_name
        associate_public_ip_address = true
        
        tags = {
          Name = "git-ec2"
        }
}

*/
