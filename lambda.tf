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

# Event Source Mapping: Conecta la cola SQS con la función Lambda
# Este recurso configura Lambda para que automáticamente procese mensajes de la cola SQS.
# AWS manejará el polling de la cola y la invocación de la función Lambda por cada mensaje.
# - batch_size: Cantidad de mensajes que Lambda procesará en cada invocación (1 = un mensaje a la vez)
# - enabled: Activa o desactiva el trigger sin eliminarlo
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.sqs_to_s3.arn
  batch_size       = 1
  enabled          = true
}
