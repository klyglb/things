provider "aws" {
  region = "us-west-2"
  profile = "admin_is_rooster"
}

resource "aws_instance" "example" {
  count         = 3
  ami           = "ami-0129bfde49ddb0ed6"
  instance_type = "t3.micro"

  tags = {
    Name = "test-instance-${count.index + 1}" 
  }
}
