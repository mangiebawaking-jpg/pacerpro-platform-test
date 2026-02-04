variable "aws_region" {
    type = string
    default = "us-east-1"
}

variable "ami_id" {
    type = string
    description = "Ami for ec2 instance"
}