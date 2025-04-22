#1. vpc
resource "aws_vpc" "newvpc" {
    cidr_block = "10.0.0.0/16"
    tags ={
        Name = "New VPC"
    }
  
}

#2. Internet Gateway
resource "aws_internet_gateway" "IG" {
    vpc_id = aws_vpc.newvpc.id
    tags = {
        Name = "IG"
    }
  
}

#3. Public Subnet
resource "aws_subnet" "PublicSubnet" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.newvpc.id
    tags = {
        Name = "PublicSubnet"
    }
    availability_zone = "eu-north-1a"
  
}

#4. Private Subnet
resource "aws_subnet" "PrivateSubnet" {
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.newvpc.id
    tags = {
        Name = "PrivateSubnet"
    }
    availability_zone = "eu-north-1b"
  
}

#5. Route Table and Routes
resource "aws_route_table" "name" {
    vpc_id = aws_vpc.newvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IG.id
    }

    tags={
            Name="Public RT"
    }  
}

#6. Subnet Association
resource "aws_route_table_association" "name" {
    route_table_id = aws_route_table.name.id
    subnet_id = aws_subnet.PublicSubnet.id
  
}

#7. Elastic IP
resource "aws_eip" "ElasticIP" {
    domain = "vpc"

    tags = {
        Name = "EIP"
    }
  
}

#8. Natgateway
resource "aws_nat_gateway" "Nat" {
    subnet_id = aws_subnet.PublicSubnet.id
    allocation_id = aws_eip.ElasticIP.id 

    tags = {
      Name = "Nat"
    }
  
}

#9. Route Table and Routes for Nat
resource "aws_route_table" "NatRT" {
    vpc_id = aws_vpc.newvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.Nat.id

    }  
    tags={
            Name="Nat RT"
        }
}

#10. Subnet Association
resource "aws_route_table_association" "NatRT" {
    route_table_id = aws_route_table.NatRT.id
    subnet_id = aws_subnet.PrivateSubnet.id
  
}

#11. Security Groups
resource "aws_security_group" "SG" {
    vpc_id = aws_vpc.newvpc.id
    name = "Allow"
    tags = {
      Name= "SG"
    }
    
    ingress {
            description = "TCP protocol for HTTP"
            from_port   = 80
            to_port     = 80
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
        }
    
    ingress {
            description = "TCP protocol for FTP"
            from_port   = 20
            to_port     = 20
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
        }

    egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
}

# 12. Key Pair
resource "aws_key_pair" "KP" {
    key_name = "public"
    public_key = file("~/.ssh/id_ed25519.pub")
  
}

# 13. Public Instance
resource "aws_instance" "Public" {
    ami = "ami-08f78cb3cc8a4578e"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.PublicSubnet.id
    associate_public_ip_address = true
    key_name = aws_key_pair.KP.key_name
    vpc_security_group_ids = [aws_security_group.SG.id]

  
}

# 14. Private Instance
resource "aws_instance" "Private" {
    ami = "ami-08f78cb3cc8a4578e"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.PrivateSubnet.id
    associate_public_ip_address = false
    key_name = aws_key_pair.KP.key_name
    vpc_security_group_ids = [aws_security_group.SG.id]

  
}