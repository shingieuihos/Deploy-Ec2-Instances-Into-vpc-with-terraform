provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Shingi-North-Virginia-Office-1"
  }
}

# Subnets
resource "aws_subnet" "web_servers" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "SNVO1web-servers"
  }
}

resource "aws_subnet" "accounting" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = {
    Name = "SNVO1accounting"
  }
}

# Key Pair
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

# Security Group
resource "aws_security_group" "shingi_nv_office" {
  name        = "ShingiNVOffice"
  description = "Allow RDP, HTTP, and HTTPS"
  vpc_id      = aws_vpc.main.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-ShingiNVOffice"
  }
}

# EC2 Instances
resource "aws_instance" "web_instance" {
  ami                         = "ami-0fa71268a899c2733"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.web_servers.id
  key_name                    = aws_key_pair.shingi_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.shingi_nv_office.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    <powershell>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $url = "https://dlcdn.apache.org/httpd/binaries/win32/httpd-2.4.57-win64-VS17.zip"
    $zipPath = "C:\\Apache24.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath "C:\\"
    & "C:\\Apache24\\bin\\httpd.exe" -k install
    $hostname = $env:COMPUTERNAME
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" }).IPAddress | Select-Object -First 1
    $html = "<h1>Server Details</h1><p><strong>Hostname:</strong> $hostname</p><p><strong>IP Address:</strong> $ip</p>"
    Set-Content -Path "C:\\Apache24\\htdocs\\index.html" -Value $html
    Start-Service -Name "Apache2.4"
    </powershell>
  EOF

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

  user_data = <<-EOF
    <powershell>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $url = "https://dlcdn.apache.org/httpd/binaries/win32/httpd-2.4.57-win64-VS17.zip"
    $zipPath = "C:\\Apache24.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath "C:\\"
    & "C:\\Apache24\\bin\\httpd.exe" -k install
    $hostname = $env:COMPUTERNAME
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" }).IPAddress | Select-Object -First 1
    $html = "<h1>Server Details</h1><p><strong>Hostname:</strong> $hostname</p><p><strong>IP Address:</strong> $ip</p>"
    Set-Content -Path "C:\\Apache24\\htdocs\\index.html" -Value $html
    Start-Service -Name "Apache2.4"
    </powershell>
  EOF

  tags = {
    Name = "SNVO1-Accounting-Server"
  }
}
