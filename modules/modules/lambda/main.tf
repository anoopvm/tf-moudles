variable "name" {
  type = string
}

variable "code_source" {
  type = string
}

variable "handler" {
  type = string
}

# variable "trigger" {
#   type = string
# }

variable "runtime" {
  type = string
}

variable "env" {
  type = map
  default = {}
}

variable "policy" {
  type = map
  default = {}
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.name
#   description   = "My awesome lambda function"
  handler       = var.handler
  runtime       = var.runtime

  source_path = "${path.module}/../${var.code_source}"

  timeout = 10

  attach_policy_statements = true
  policy_statements = var.policy
  publish = true

  environment_variables = var.env


#   tags = {
#     Name = "my-lambda1"
#   }
}

output "arn" {
  value = module.lambda_function.lambda_function_arn
}

output "lambda_invoke_arn" {
  value = module.lambda_function.lambda_function_invoke_arn
}

output "lambda_function_name" {
  value = module.lambda_function.lambda_function_name
}
