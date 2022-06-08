provider "aws" {
  region                  = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                 = "default"
}

resource "aws_instance" "ubuntu" {
  ami                         = var.amiid[0]
  count                       = 1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1.id
  associate_public_ip_address = true
  key_name                    = "ansibleserverskey"
  vpc_security_group_ids      = [aws_security_group.web.id]
  #disable_api_termination = false

  tags = {
    Name = "AnsibleServer${count.index}"

  }

}
resource "null_resource" "makedir" {
  count = 1
  provisioner "remote-exec" {
    inline = ["mkdir rafeeq"]
    connection {
      host = aws_instance.ubuntu[count.index].public_dns
      #host="3.222.251.38"
      type = "ssh"
      user = "ec2-user"
      #private_key    = "newkey"
      #private_key ="privatekey_key.ppk"
      private_key = file("ansibleserverskey.pem")
      timeout = "1m"
      
    }

  }
  depends_on = [aws_instance.ubuntu]
}


resource "aws_security_group" "web" {

  name        = "ansible-sec-group"
  description = " Allows SSH"
  vpc_id      = aws_vpc.prodvpcterraform.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = " Allow outside"
    #name = "To install ansible"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    
  
    #prefix_list_ids = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
  }
}



resource "aws_vpc" "prodvpcterraform" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {

    Name = "VPC for Ansible"
  }
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.prodvpcterraform.id
  cidr_block = "10.0.0.0/24"
  tags = {

    Name = "Subnet for Ansible"
  }

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prodvpcterraform.id

  tags = {
    Name = "ansible igw"
  }
}

resource "aws_route_table" "table" {
  vpc_id = aws_vpc.prodvpcterraform.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "ansibleroute"
  }
}

resource "aws_route_table_association" "rtassociation" {
  #gateway_id     = aws_internet_gateway.gw.id
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.table.id
}
