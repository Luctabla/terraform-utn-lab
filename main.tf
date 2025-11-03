terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "zlab"
  region  = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# S3 Bucket
resource "aws_s3_bucket" "lambda_output" {
  bucket = "${var.project_name}-output-${var.environment}"

  tags = {
    Name = "${var.project_name}-output"
  }
}

resource "aws_s3_bucket_versioning" "lambda_output" {
  bucket = aws_s3_bucket.lambda_output.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SQS Queue
resource "aws_sqs_queue" "main" {
  name                       = "${var.project_name}-queue-${var.environment}"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400

  tags = {
    Name = "${var.project_name}-queue"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-role"
  }
}

# IAM Policy for Lambda to access SQS and S3
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.lambda_output.arn}/*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "sqs_to_s3" {
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-sqs-to-s3-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = filebase64sha256("lambda_function.zip")
  runtime         = "python3.12"
  timeout         = 60

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.lambda_output.id
    }
  }

  tags = {
    Name = "${var.project_name}-sqs-to-s3"
  }
}

# Lambda Event Source Mapping (SQS trigger)
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.sqs_to_s3.arn
  batch_size       = 1
  enabled          = true
}
