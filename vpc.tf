resource "aws_vpc" "prefect_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prefect_vpc.id
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.prefect_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "prefect-ecs-public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = 3
  vpc_id                  = aws_vpc.prefect_vpc.id
  cidr_block              = "10.0.${count.index + 4}.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "prefect-ecs-private-${count.index + 1}"
  }
}

resource "aws_eip" "nat" {
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prefect_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "prefect-ecs-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.prefect_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "prefect-ecs-private"
  }
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

data "aws_availability_zones" "available" {}