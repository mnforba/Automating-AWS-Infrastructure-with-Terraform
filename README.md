# Automating-AWS-Infrastructure-with-Terraform
This project introduces beginners to Cloud Infrastructure Automation: A case study of Amazon Web Service (AWS).

Prerequisites

Terraform installation:
This can be downloaded here. Choose the correct installation package for your operating system (OS). Choose amd64 if you run an x64 processor-based computer.

For windows, create a terraform folder and copy (or cut) the downloaded terraform file into the created folder. This can be achieved from the terminal by running:

cd
mkdir terraform
cd terraform
copy <path to the downloaded terraform file/terraform.exe> c:/terraform
Navigate to environment variables under system properties and add c:/terraform to your path. Alternatively, this can be achieved from the terminal by running:

export PATH=$PATH:~/terraform
Creation of AWS account: You can create a trial account that comes with 300 USD free credit, which is valid for 12 months. This can be done here. Simply fill out the necessary details, and you are good to go with your free tier account.

Navigate to IAM under your AWS Console and click on Key Management. Create a new key pair, download the IAM key (please keep this secured, as you only get to see the credentials on your AWS console once, except for the downloaded CSV file containing the credentials).

Download AWS CLI. See the installation guide here.

Download the appropriate version of Microsoft Visual Studio Code (VSC) for your computer here. Please note that you can use any IDE of your choice. However, VSC is the most recommended for this project.

Create a new file named main.tf (note that you can use a name of your choice for this file). Specify your service provider in a code block as follows:

provider "aws" {
access_key = "AWS_ACCESS_KEY_ID"
secret_key = "AWS_ACCESS_SECRET_KEY"
region = "YOUR_AWS_REGION"
}
Note that the above keys can be found in the CSV file from step 3 above. However, it should be noted that AWS is highly sensitive, and does not overlook credential leakage (expose of sensitive keys and/or details) on public domains such as GitHub.

Next, we proceed to create resources in our AWS instance, by automating the process right from our terraform file. This project created 9 resources in our AWS instance right from terraform. These resources are:

# 1: Create a Virtual Private Cloud (vpc)

resource"aws_vpc""prod-vpc" {
  cidr_block="10.0.0.0/16"
  tags={
    Name = "production"
  }
}
NB:

You can change the cidr_block IP to an IP of choice, but you need to ensure that the provided IP is usable.

# 2: Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "internet_gateway"
  }
}
# 3: Create a Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod Route Table"
  }
}
# 4: Create a Subnet

resource"aws_subnet""subnet-1" {

  vpc_id     =aws_vpc.prod-vpc.id

  cidr_block="10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags={

    Name = "prod-subnet"

  }

}
# 5: Associate Subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
# 6: Create a Security Group to allow ports 22, 80, 443

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
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
    description = "<write as you like>"
  }
  tags = {
    Name = "allow_web_traffic"
  }
}
# 7: Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web_server_nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]
}
# 8: Assign an elastic ip to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web_server_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}
# 9: Create Ubuntu server and install/enable apache2

resource "aws_instance" "web_server" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name      = "aws-main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web_server_nic.id
     }

     user_data = <<-EOF
                    #!/bin/bash
                    sudo apt update -y
                    sudo apt install apache2 =y
                    sudo systemctl start apache2
                    sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                    EOF
      tags= {
        Name = "web_server"
      }
}
NB:

The above resources are present in the main.tf file.
You should try to avoid setting cidr_block to 0.0.0.0/0. This allows for connection to the instance from anywhere and makes it vulnerable. Hence, you should try to use a specific IP address. The above resources are present in the main.tf file.
For the sake of deployment to a public domain, we shall create additional files such as variables.tf, and terraform.tfvars

The content of variables.tf is given below:

#AWS authentication variables
variable "aws_access_key" {
  type = string
  description = "AWS Access Key"
}
variable "aws_secret_key" {
  type = string
  description = "AWS Secret Key"
}
#AWS Region
variable "aws_region" {
  type = string
  description = "AWS Region"
  default = "us-east-1"
}
#Define application environment
variable "app_environment" {
  type = string
  description = "Application Environment"
  default = "prod"
}
The content of terraform.tfvars

#AWS authentication variables
aws_access_key = "AWS_ACCESS_KEY_ID"
aws_secret_key = "AWS_ACCESS_SECRET_KEY"
The above keys can be obtained from AWS IAM

Note however that your AWS account will be temporarily suspended if you expose your credentials. To prevent this exposure, simply create a .gitignore file and add *.tfvars to the file.

After setting up your workflow, run:

# initialize terraform

terraform init
# Check the resources that will be added to your AWS Infrastructure

terraform plan
# Apply (create) the resources

terraform apply
If you run terraform apply, you will get a prompt to type yes. If you do not want to get any prompt, run

terraform apply -auto-approve
Feel free to fork this repo, raise a pull request to contribute to this project, and raise an issue if you encounter any challenge.
