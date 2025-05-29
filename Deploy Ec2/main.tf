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


  user_data = <<-EOF
    <powershell>
    # Enable TLS 1.2 (required for some downloads)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download Apache Lounge Windows binaries
    $url = "https://dlcdn.apache.org/httpd/binaries/win32/httpd-2.4.57-win64-VS17.zip"
    $zipPath = "C:\\Apache24.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    # Extract the archive
    Expand-Archive -Path $zipPath -DestinationPath "C:\\"

    # Install Apache as a service
    & "C:\\Apache24\\bin\\httpd.exe" -k install

    # Generate simple HTML page with hostname and IP
    $hostname = $env:COMPUTERNAME
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface" -and $_.IPAddress -notlike "169.*" }).IPAddress | Select-Object -First 1
    $html = "<h1>Server Details</h1><p><strong>Hostname:</strong> $hostname</p><p><strong>IP Address:</strong> $ip</p>"
    Set-Content -Path "C:\\Apache24\\htdocs\\index.html" -Value $html

    # Start the Apache service
    Start-Service -Name "Apache2.4"
    </powershell>
  EOF

  tags = {
    Name = "SNVO1-Web-Server"
  }
}
  
  user_data = <<-EOF
    <powershell>
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $url = "https://dlcdn.apache.org/httpd/binaries/win32/httpd-2.4.57-win64-VS17.zip"
    $zipPath = "C:\\Apache24.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath "C:\\"
    & "C:\\Apache24\\bin\\httpd.exe" -k install
    $hostname = $env:COMPUTERNAME
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -ne "Loopback Pseudo-Interface" -and $_.IPAddress -notlike "169.*" }).IPAddress | Select-Object -First 1
    $html = "<h1>Server Details</h1><p><strong>Hostname:</strong> $hostname</p><p><strong>IP Address:</strong> $ip</p>"
    Set-Content -Path "C:\\Apache24\\htdocs\\index.html" -Value $html
    Start-Service -Name "Apache2.4"
    </powershell>
  EOF

  tags = {
    Name = "SNVO1-Accounting-Server"
  }
}

