# 1. Create vpc - create key-pair for ssh, EC2 instance
# 2. Create Internet Gateway - get public IP, send data to the internet
# 3. Create Custom Route Table
# 4. Create a subnet
# 5. Associate subnet with Route Table 
# 6. Create security group to allow port 22, 80, 443 - ssh, http, https
# 7. Create a network interface with an ip in the subnet that was created in step 4
# 8. Assign an elastic IP to the network interface created in step 7
# 9. Create Ubuntu server and install/enable apache2

# Configure the AWS Provider
provider "aws" {
    region = "us-west-2"
    access_key = "<your access key>"
    secret_key = "<your secret key>"
}




# Step 1 create vpc
resource "aws_vpc" "prod-vpc" {
    cidr_block       = "10.0.0.0/16"  

    tags = {
        Name = "prod-vpc"
    }
}

# Step 2 create internet gateway
resource "aws_internet_gateway" "gateway" {
    vpc_id = aws_vpc.prod-vpc.id

    tags = {
        Name = "prod-gateway"
    }
}

# Step 3 create route table
resource "aws_route_table" "prod-route-table" {
    vpc_id = aws_vpc.prod-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway.id
    }

    route {
        ipv6_cidr_block        = "::/0"
        gateway_id = aws_internet_gateway.gateway.id
    }

    tags = {
        Name = "prod-route-table"
    }                         
}

# Step 4 create the subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.prod-vpc.id
    cidr_block       = var.subnet_prefix
    availability_zone = "us-west-2a"
    tags = {
        Name = "prod-subnet"
  }
}

# Step 5 route table association
resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.prod-route-table.id
}

# Step 6 create security group
resource "aws_security_group" "allow-web" {
    name        = "allow-web-traffic"
    description = "Allow web inbound traffic"
    vpc_id      = aws_vpc.prod-vpc.id

    ingress {
        description      = "HTTPS"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "SSH"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "allow-web-traffic"
    }
}

# Step 7 create a network interface
resource "aws_network_interface" "web-server-nic" {
    subnet_id       = aws_subnet.subnet-1.id
    private_ips     = ["10.0.0.50"]
    security_groups = [aws_security_group.allow-web.id]

}

# Step 8 Assign an elastic IP
resource "aws_eip" "one" {
    vpc                       = true
    network_interface         = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.0.50"
    depends_on = [aws_internet_gateway.gateway]
}

# Step 9 Create Ubuntu server
resource "aws_instance" "web-server-instance" {
    ami           = "ami-0ddf424f81ddb0720"
    instance_type = "t2.micro"
    availability_zone = "us-west-2a"
    key_name = "main-key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }

    user_data = <<-EOF
                #! /bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c "echo My first web server > /var/www/html/index.html"
                EOF

    tags = {
        Name = "prod-web-server"
    }
}

