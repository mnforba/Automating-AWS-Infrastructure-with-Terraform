#AWS authentication variables
variable "aws_access_key" {
  type = string
  description = "AWS Access Key"
  default = "AKIAXOZZVLD6R3RI254P"
}
variable "aws_secret_key" {
  type = string
  description = "AWS Secret Key"
  default = "QLOfayeRpMceMjTWXldblpIsTXBa62rnaeghlRR1"
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


