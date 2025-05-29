provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "shingi_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "shingi_key_pair" {
  key_name   = "ShingiNVOfficeKey"
  public_key = tls_private_key.shingi_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.shingi_key.private_key_pem
  filename = "${path.module}/ShingiNVOfficeKey.pem"
}


resource "aws_instance" "web_instance" {
  ami                         = "ami-0fa71268a899c2733"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.web_servers.id
  key_name                    = aws_key_pair.shingi_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.shingi_nv_office.id]
  associate_public_ip_address = true

  tags = {
    Name = "SNVO1-Web-Server"
  }
}

resource "aws_instance" "accounting_instance" {
  ami                         = "ami-0596166f97ee983d1"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.accounting.id
  key_name                    = aws_key_pair.shingi_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.shingi_nv_office.id]
  associate_public_ip_address = true

  tags = {
    Name = "SNVO1-Accounting-Server"
  }
}
resource "aws_security_group" "shingi_nv_office" {
  name        = "ShingiNVOffice"
  description = "Allow RDP, HTTP, and HTTPS"
  vpc_id      =  "vpc-0760f6a08cad0fc4e"

  ingress {
    description = "Allow RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-ShingiNVOffice"
  }
}

