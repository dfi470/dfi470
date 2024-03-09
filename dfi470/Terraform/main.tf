resource "aws_vpc" "vpc-demo" {
    cidr_block = var.cidr  
}

resource "aws_subnet" "subnet-demo" {
    vpc_id = aws_vpc.vpc-demo.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "eu-north-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet-demo1" {
    vpc_id = aws_vpc.vpc-demo.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-north-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw-demo" {
  vpc_id = aws_vpc.vpc-demo.id
}

resource "aws_route_table" "demo-rt" {
    vpc_id = aws_vpc.vpc-demo.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw-demo.id
    }
}

resource "aws_route_table_association" "rta-demo" {
  subnet_id = aws_subnet.subnet-demo.id
  route_table_id = aws_route_table.demo-rt.id
}

resource "aws_route_table_association" "rta-demo-1" {
  subnet_id = aws_subnet.subnet-demo1.id
  route_table_id = aws_route_table.demo-rt.id
}

resource "aws_security_group" "demosg" {
  name = "web-sg"
  vpc_id = aws_vpc.vpc-demo.id

  ingress {
    description = "http from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "s3-demo" {
  bucket = "dfi4701368959"
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.s3-demo.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.s3-demo.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.s3-demo.id
  acl    = "public-read"
}

resource "aws_instance" "webserver" {
  ami = "ami-00381a880aa48c6c6"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.demosg.id]
  subnet_id = aws_subnet.subnet-demo.id
  user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "webserver1" {
  ami = "ami-00381a880aa48c6c6"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.demosg.id]
  subnet_id = aws_subnet.subnet-demo1.id
  user_data = base64encode(file("userdata1.sh"))
}
