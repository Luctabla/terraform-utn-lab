# Lambda Function
resource "aws_lambda_function" "sqs_to_s3" {
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-sqs-to-s3-${terraform.workspace}"
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
    Name = "${var.project_name}-sqs-to-s3-${terraform.workspace}"
  }
}

# Lambda Event Source Mapping (SQS trigger)
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.sqs_to_s3.arn
  batch_size       = 1
  enabled          = true
}
