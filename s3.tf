# S3 Bucket for Lambda Output
resource "aws_s3_bucket" "lambda_output" {
  bucket = "${var.project_name}-output-${terraform.workspace}"

  tags = {
    Name = "${var.project_name}-output-${terraform.workspace}"
  }
}

resource "aws_s3_bucket_versioning" "lambda_output" {
  bucket = aws_s3_bucket.lambda_output.id

  versioning_configuration {
    status = "Enabled"
  }
}
