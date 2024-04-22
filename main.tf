provider "aws" {
  region = "us-east-1" # Defina a região desejada
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "mapfre-tfenabled"
    key    = "ce/aws-vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16" # Bloco CIDR da VPC
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "CE-Mapfre-VPC"
  }
}

# Criar um gateway de internet
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "CE-Mapfre-Igw"
  }
}

# Criar tabela de rotas
resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Criar sub-redes em 3 zonas de disponibilidade
resource "aws_subnet" "my_subnets" {
  count                   = 3
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       =  element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "CE-Mapfre-subnet-${count.index}"
  }
}

# Associar rota do gateway de internet para cada subnet criada
resource "aws_route_table_association" "my_route_associations" {
  count          = 3
  subnet_id      = tolist(aws_subnet.my_subnets.*.id)[count.index]
  route_table_id = aws_route_table.my_route.id
}

resource "aws_security_group" "my_sg" {
  name        = "CE-Mapfre-SG"
  description = "My security group for EC2 instances"

  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir acesso SSH de qualquer lugar (não recomendado para produção)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Permitir acesso à internet para baixar arquivos (atualizações ou novas instalações)
  }
}

resource "aws_instance" "my_instance" {
  ami                         = var.ami_lnx_virg # ID da AMI do RHEL 9
  instance_type               = "t2.micro"       # Tipo de instância
  key_name                    = "CE-Mapfre"      # Nome da chave SSH
  subnet_id                   = data.terraform_remote_state.vpc.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.vpc.outputs.security_group_id]
  iam_instance_profile        = "SSM-Access" # Role de acesso
  associate_public_ip_address = true         # Habilitar IP público  

  # Instalação do agente SSM após máquina provisionada
  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent
              EOF

  tags = {
    Name = "CE-Mapfre-RH9"
  }
}