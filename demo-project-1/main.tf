
resource "aws_vpc" "my_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {

  Name = "TF-Docker-VPC"

}
  
}


resource "aws_subnet" "my_subnet" {


  cidr_block = "10.0.0.0/16"
  vpc_id = aws_vpc.my_vpc.id 
  availability_zone = "us-east-1a" 
  map_public_ip_on_launch = true

  tags = {
    Name = "TF-Docker-Subnet"
  }
}

resource "aws_internet_gateway" "my_igw" {

  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "TF-Docker-IGW"
  }


}

resource "aws_route_table" "my_rt" {

 vpc_id = aws_vpc.my_vpc.id
 route {

   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.my_igw.id
}
 tags = {
    Name = "TF-Docker-RT"
  }

}

# 5. Associate Subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_rt.id
}

# 6. Create Security Group (Firewall)
resource "aws_security_group" "my_sg" {
  name        = "tf-docker-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  # Allow HTTP (Port 80) for Nginx
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (Port 22) for troubleshooting
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TF-Docker-SG"
  }
}

resource "aws_instance" "my_server" {
  ami           = "ami-0b6c6ebed2801a5cb" 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d -p 80:80 nginx
              EOF
  tags = {
    Name = "TF-Docker-Server"
  }
}












