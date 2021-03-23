#----------------------------------------
# Configure EC2 instances
#----------------------------------------

# Creating Bastion-Host
resource "aws_instance" "bastion_host" {
  ami           = "ami-0767046d1677be5a0"
  instance_type = "t2.micro"
  key_name      = "aws-test"
  subnet_id     = aws_subnet.Privat.id
  vpc_security_group_ids      = [module.security_group.public_subnet.id]
  associate_public_ip_address = true
  depends_on    = [aws_subnet.Public]

  tags = {
      Name = "bastion_host"
  }
}

# Creating Web-Serwer
resource "aws_instance" "web-server" {
  ami           = "ami-0767046d1677be5a0"
  instance_type = "t2.micro"
  key_name      = "aws-test"
  subnet_id     = aws_subnet.Privat.id
  depends_on    = [aws_subnet.Privat]

  tags = {
      Name = "web-server"
  }
}