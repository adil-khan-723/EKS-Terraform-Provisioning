resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.env}-vpc"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "${var.env}-igw"
    }
}

resource "aws_subnet" "private" {
    count = 2
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.${count.index + 1}.0/24"
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = false

    tags = {
        Name = "${var.env}-private-${count.index + 1}-${var.azs[count.index]}"
        "kubernetes.io/role/internal-elb" = "1"
        "kubernetes.io/cluster/${var.env}-${var.eks-name}" = "owned"
    }
}

resource "aws_subnet" "public" {
    count = 2
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.${count.index + 3}.0/24"
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.env}-public-${count.index + 1}-${var.azs[count.index]}"
        "kubernetes.io/role/elb" = "1"
        "kubernetes.io/cluster/${var.env}-${var.eks-name}" = "owned"
    }
}

resource "aws_eip" "eip" { 
    domain = "vpc"

    tags = {
        Name = "${var.env}-eip"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.eip.id
    subnet_id = aws_subnet.public[0].id
    depends_on = [aws_internet_gateway.igw]

    tags = {
        Name = "${var.env}-nat"
    }
}

resource "aws_route_table" "private-rt" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "${var.env}-private-rt"
    }

}

resource "aws_route_table" "public-rt" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "${var.env}-public-rt"
    }
}

resource "aws_route_table_association" "private-association-1" {
    subnet_id = aws_subnet.private[0].id
    route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "private-association-2" {
    subnet_id = aws_subnet.private[1].id
    route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "public-association-1" {
    subnet_id = aws_subnet.public[0].id
    route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-association-2" {
    subnet_id = aws_subnet.public[1].id
    route_table_id = aws_route_table.public-rt.id
}