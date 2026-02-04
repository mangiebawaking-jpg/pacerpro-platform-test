terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version ="~> 5.0"
        }
    }
}
provider "aws" {
    region = var.aws_region
}

resource "aws_sns_topic" "alerts" {
    name = " sumo-ec2-restart-alerts"
}

resource "aws_iam_role" "lambda_role" {
    name = "lambda-ec2-restart-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17,
        Statement =[{
            Effect = "Allow",
            Principal = { Service = "lambda.amazonaws.com" },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_policy" "lambda_policy" {
    name = "lmbad-ec2-restart-policy"
    policy = jsonencode({
        Version = "2012-10-17,
        Statement = [
          {
            Effect = "Allow",
            Action = ["ec2:rebootInstances"],
            Resource = "*"
          },
          {
            Effect = "Allow",
            Action = ["sns:Publish"],
            Resource = "aws_sns_topic.alerts.arn"
          },
          {
            Effect = "Allow",
            Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            Resource = "*"
          }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}

reosurce "aws_instance" "web" {
    ami = var.ami_id
    instance_type = "t2.micro"

    tags = {
        Name = "pacepro-test-ec2"
    }
}

data "archive_file" "lambda_zip" {
    type = "zip"
    source_file = "../lambda_function/lambda_function.py"
    output_path = "${path.module}/lambda-function.zip"
}

resource "aws_lambda_function" 'restart-ec2" {
    function_name = "restart-ec2-from-sumo"
    handler = "lambda_function.lambda_handler"
    runtime = "python3.11"
    role = aws_iam_role.lambda_role.arn

    filename = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256

    environment {
        variables = {
            INSTANCE_ID = aws_instance.web.ami_id
            SNS_TOPIC_ARn = aws_sns_topic.alerts.arn
        }
    }
}
