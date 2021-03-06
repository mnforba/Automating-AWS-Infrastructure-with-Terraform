#AWS authentication variables
variable "aws_access_key" {
  type = string
  description = "AWS Access Key"
  #default = "xxxxxxxxxxxxxxxxxxx"
}
variable "aws_secret_key" {
  type = string
  description = "AWS Secret Key"
  #default = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
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
  default = "dev"
}


