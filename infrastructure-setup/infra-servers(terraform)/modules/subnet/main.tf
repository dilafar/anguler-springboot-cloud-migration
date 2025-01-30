resource "aws_subnet" "dev-subnet" {
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone_1
  cidr_block        = var.subnet_cidr_block[0]

  tags = {
    Name = "${var.env_prefix}-subnet"
  }

}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone_2
  cidr_block        = var.subnet_cidr_block[1]

  tags = {
    Name = "${var.env_prefix}-subnet-2"
  }

}

resource "aws_subnet" "dev-subnet-3" {
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone_3
  cidr_block        = var.subnet_cidr_block[2]

  tags = {
    Name = "${var.env_prefix}-subnet-3"
  }

}

resource "aws_subnet" "dev-subnet-4" {
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone_4
  cidr_block        = var.subnet_cidr_block[3]

  tags = {
    Name = "${var.env_prefix}-subnet-4"
  }

}

resource "aws_subnet" "dev-subnet-5" {
  vpc_id            = var.vpc_id
  availability_zone = var.availability_zone_5
  cidr_block        = var.subnet_cidr_block[4]

  tags = {
    Name = "${var.env_prefix}-subnet-5"
  }

}

resource "aws_internet_gateway" "dev-gateway" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}


resource "aws_route_table" "route-table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-gateway.id
  }

  tags = {
    Name = "${var.env_prefix}-main-route_table"
  }
}

resource "aws_route_table_association" "rt-association-pubsub1" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.dev-subnet.id
}

resource "aws_route_table_association" "rt-association-pubsub2" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.dev-subnet-2.id
}
resource "aws_route_table_association" "rt-association-pubsub3" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.dev-subnet-3.id
}
resource "aws_route_table_association" "rt-association-pubsub4" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.dev-subnet-4.id
}
resource "aws_route_table_association" "rt-association-pubsub5" {
  route_table_id = aws_route_table.route-table.id
  subnet_id      = aws_subnet.dev-subnet-5.id
}