variable "handle_requests_lambda" {
  type = string
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  create_api_domain_name = false

  name          = "dev-http"
  description   = "My awesome HTTP API Gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  domain_name                 = "terraform-aws-modules.modules.tf"

  # Routes and integrations
  integrations = {
    "POST /requests" = {
      lambda_arn             = var.handle_requests_lambda
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "GET /requests" = {
      lambda_arn             = var.handle_requests_lambda
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

  }  
}
