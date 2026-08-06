terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket for Image Uploads
resource "aws_s3_bucket" "image_bucket" {
  bucket_prefix = "ai-image-analyzer-bucket-"
  force_destroy = true
}

# 2. DynamoDB Table for Metadata
resource "aws_dynamodb_table" "image_metadata" {
  name         = "ImageMetadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ImageID"

  attribute {
    name = "ImageID"
    type = "S"
  }
}

# 3. SNS Topic for Notifications
resource "aws_sns_topic" "image_alerts" {
  name = "ImageAnalysisAlerts"
}

# 4. IAM Role for Lambda Function
resource "aws_iam_role" "lambda_exec_role" {
  name = "serverless_image_analyzer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM Policy attaching necessary permissions
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess" # For demo purposes
}

# 5. Lambda Function
resource "aws_lambda_function" "image_processor" {
  filename      = "lambda.zip" # Dummy archive name for IaC declaration
  function_name = "ImageAnalyzerFunction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.image_metadata.name
      SNS_TOPIC_ARN = aws_sns_topic.image_alerts.arn
    }
  }
}

# 6. API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "image-analyzer-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.image_processor.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_images_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /images"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
