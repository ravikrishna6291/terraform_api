# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type = string
}

variable "profile" {
  description = "aws cred profile in local"
  type        = string
  default     = "default"
}


variable "api_stage_name" {
  description = "API stage"
  type        = string
}


variable "lambda_authorizer_uri" {
  description = "lambda_authorizer_uri"
  type        = string
}


variable "lambda_function_name" {
  description = "lambda function name to be deployed"
  type        = string
}


variable "lambda_function_uri" {
  description = "lambda_funtcion_uri"
  type        = string
}

variable "api_name" {
  description = "name of the api"
  type        = string
}


variable "api_basepath" {
  description = "base path of api"
  type        = string
}




