terraform {
  backend "s3" {
    bucket = "139012737147-us-east-1-tfstate"
    key    = "scaffolding-automations"
    region = "us-east-1"
  }
}

locals {
  package_url   = "index.zip"
  function_name = "scaffolding-automations-lambda"
  downloaded    = "downloaded_package_${md5(local.package_url)}.zip"
}

# resource "null_resource" "download_package" {
#   triggers = {
#     downloaded = local.downloaded
#   }

#   provisioner "local-exec" {
#     command = "curl -L -o ${local.downloaded} ${local.package_url}"
#   }
# }

# data "null_data_source" "downloaded_package" {
#   inputs = {
#     id       = null_resource.download_package.id
#     filename = local.downloaded
#   }
# }

resource "aws_cloudwatch_log_group" "logs" {
  name = local.function_name
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name                   = "scaffolding-automations-http"
  description            = "My awesome HTTP API Gateway"
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
    "ANY /" = {
      lambda_arn         = module.lambda_function.this_lambda_function_arn
      integration_type   = "AWS_PROXY"
      integration_method = "POST"
    }

    "$default" = {
      lambda_arn         = module.lambda_function.this_lambda_function_arn
      integration_type   = "AWS_PROXY"
      integration_method = "POST"
    }
  }
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 1.0"

  function_name = local.function_name
  description   = "My awesome lambda function"
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  publish = true

  create_package         = false
  local_existing_package = local.package_url

  allowed_triggers = {
    yes = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.this_apigatewayv2_api_execution_arn}/*/*/"
    }
  }
}
