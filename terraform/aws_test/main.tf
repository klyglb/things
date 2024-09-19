provider "aws" {
  region  = "eu-central-1"            # Указываем регион AWS, где будут созданы ресурсы
  profile = "admin_is_rooster"      # Профиль AWS для аутентификации (можно убрать, если не используешь профили)
}

# Создаём VPC (Virtual Private Cloud) - виртуальная сеть для изоляции ресурсов
resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"        # Определяем диапазон IP-адресов для VPC

  tags = {
    Name = "test-vpc"               # Тег для удобства идентификации
  }
}

# Создаём подсеть (Subnet) внутри VPC
resource "aws_subnet" "test_subnet" {
  vpc_id            = aws_vpc.test_vpc.id    # Привязываем подсеть к созданной VPC
  cidr_block        = "10.0.1.0/24"          # Диапазон IP-адресов для подсети
  availability_zone = "eu-central-1c"           # Зона доступности AWS

  tags = {
    Name = "test-subnet"             # Тег для удобства идентификации
  }
}

# Создаём Интернет-шлюз (Internet Gateway) для доступа инстансов в интернет
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id       # Привязываем интернет-шлюз к созданной VPC

  tags = {
    Name = "test-igw"                # Тег для удобства идентификации
  }
}

# Создаём маршрутную таблицу (Route Table) для управления трафиком
resource "aws_route_table" "test_route_table" {
  vpc_id = aws_vpc.test_vpc.id       # Привязываем маршрутную таблицу к созданной VPC

  route {
    cidr_block = "0.0.0.0/0"         # Разрешаем весь трафик (выход в интернет)
    gateway_id = aws_internet_gateway.test_igw.id  # Указываем интернет-шлюз как маршрут
  }

  tags = {
    Name = "test-route-table"         # Тег для удобства идентификации
  }
}

# Ассоциируем маршрутную таблицу с созданной подсетью
resource "aws_route_table_association" "test_route_assoc" {
  subnet_id      = aws_subnet.test_subnet.id   # Привязываем маршрутную таблицу к подсети
  route_table_id = aws_route_table.test_route_table.id
}

# Создаём секьюрити-группу (Security Group) для управления правилами доступа
resource "aws_security_group" "test_sg" {
  vpc_id = aws_vpc.test_vpc.id        # Привязываем секьюрити-группу к VPC

  # Правило входящего трафика (ingress) для SSH (порт 22)
  ingress {
    from_port   = 22                  # Начальный порт
    to_port     = 22                  # Конечный порт
    protocol    = "tcp"               # Протокол TCP
    cidr_blocks = ["0.0.0.0/0"]       # Разрешаем доступ из любого IP (лучше ограничить)
  }

  # Правило входящего трафика (ingress) для HTTP (порт 80)
  ingress {
    from_port   = 80                  # Начальный порт
    to_port     = 80                  # Конечный порт
    protocol    = "tcp"               # Протокол TCP
    cidr_blocks = ["0.0.0.0/0"]       # Разрешаем доступ из любого IP
  }

  # Правило исходящего трафика (egress) - разрешаем весь исходящий трафик
  egress {
    from_port   = 0                   # Разрешаем все порты
    to_port     = 0
    protocol    = "-1"                # -1 означает "любой протокол"
    cidr_blocks = ["0.0.0.0/0"]       # Разрешаем исходящий трафик в интернет
  }

  tags = {
    Name = "test-sg"                  # Тег для удобства идентификации
  }
}

# Создаём EC2 инстансы
resource "aws_instance" "test_instance" {
  count         = 3                   # Создаём 3 инстанса
  ami           = "ami-00f07845aed8c0ee7"  # AMI (Amazon Machine Image) для инстансов
  instance_type = "t2.micro"         
  subnet_id     = aws_subnet.test_subnet.id  # Привязываем инстансы к созданной подсети
  vpc_security_group_ids = [aws_security_group.test_sg.id]  # Привязываем секьюрити-группы для VPC

  tags = {
    Name = "test-instance-${count.index + 1}"  # Генерируем уникальные имена для инстансов
  }
}

# Создаём Elastic IP для каждого инстанса
resource "aws_eip" "test_eip" {
  count    = 3
  instance = aws_instance.test_instance[count.index].id  # Привязываем EIP к инстансу
  domain = "vpc"

  tags = {
    Name = "test-eip-${count.index + 1}"  # Генерируем уникальные имена для Elastic IP
  }
}

output "instance_public_ips" {
  value = [for eip in aws_eip.test_eip : eip.public_ip]
}
