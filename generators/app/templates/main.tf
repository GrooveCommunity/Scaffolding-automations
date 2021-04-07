terraform {
  backend "s3" {
    bucket = "139012737147-us-east-1-tfstate"
    key    = "<%= name %>"
    region = "us-east-1"
  }
}

variable "functions" {
  type = map(
    object({
      path = string
      method = string
      description = string
    })
  )
  default = <%- functions %>
}

variable "project_name" {
  type = string
  default = "<%= name %>"
}

variable "project_description" {
  type = string
  default = "<%= description %>"
}

provider "aws" {
  region = "us-east-1"
}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "npm run build"
  }

  provisioner "local-exec" {
    when = destroy
    command = "npm run clear"
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = var.project_name
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name                   = "${var.project_name}-http"
  description            = var.project_description
  protocol_type          = "HTTP"
  create_api_domain_name = false

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.logs.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  integrations = {
    for key in keys(var.functions):
      "${var.functions[key].method} ${var.functions[key].path}" => {
        lambda_arn         = module.lambda_function[key].this_lambda_function_arn
        integration_method = var.functions[key].method
        integration_type   = "AWS_PROXY"
      }
  }
}

data "archive_file" "zip_file" {
  for_each = var.functions

  type        = "zip"
  source_file = "dist/${each.key}.js"
  output_path = "${each.key}.zip"

  depends_on = [
    null_resource.build
  ]
}

module "lambda_function" {
  source  =    "terraform-aws-modules/lambda/aws"
  version = "~> 1.0"

  for_each = var.functions

  function_name          = "${var.project_name}-${each.key}"
  handler                = "${each.key}.handler"
  description            = each.value.description
  runtime                = "nodejs12.x"

  publish                = true
  create_package         = false
  local_existing_package = "${each.key}.zip"

  allowed_triggers       = {
    yes = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.this_apigatewayv2_api_execution_arn}/*/${each.value.method}${each.value.path}"
    }
  }
}
