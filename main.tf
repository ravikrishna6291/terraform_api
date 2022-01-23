terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.aws_region
}

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "${var.api_name} REST API"
    endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = var.api_basepath
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.this.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_authorizer" "this" {
  name           = "authorizer"
  rest_api_id    = aws_api_gateway_rest_api.this.id
  authorizer_uri = aws_lambda_function.authorizer.invoke_arn
}

resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.this.id

}

resource "aws_api_gateway_integration" "this" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*/*"
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.api_stage_name
}


resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_api_gateway_method.this,aws_api_gateway_integration.this
  ]
}


resource "aws_lambda_function" "authorizer" {
  filename      = "lambda-authorizer.zip"
  function_name = "authorizer"
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}


resource "aws_lambda_function" "this" {
  filename      = "lambda_code.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "LambdaFunctionOverHttps.handler"
  runtime       = "python3.8"
}

resource "aws_lambda_alias" "green_alias" {
  name             = "greenalias"
  description      = "alias for green version"
  function_name    = aws_lambda_function.this.function_name
  function_version = "$LATEST"
}


resource "aws_iam_role" "iam_role_for_lambda" {
name = "iam_role_for_lambda"
assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
]
}
EOF
}
