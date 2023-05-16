module "serverless" {
  source = "../modules/serverless"
}

module "handle_requests_lambda" {
  source = "../modules/lambda"

  name        = "request-handler"
  runtime     = "nodejs14.x"
  code_source = "src/request-handler"
  handler     = "app.handleRequest"
  policy = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:us-east-1:889332921058:table/avm-88eewe-appRequests"]
    },
    sqs = {
      effect    = "Allow",
      actions   = ["sqs:*"],
      resources = ["arn:aws:sqs:us-east-1:889332921058:requestQueue"]
    }
  }
  env = {
    "QUEUE_NAME"     = module.serverless.sqs_queue_name
    "DYNAMODB_TABLE" = module.serverless.dynamodb_table
  }
}

module "backend_processing" {
  source = "../modules/lambda"

  name        = "backend_processing"
  runtime     = "python3.7"
  code_source = "src/backend"
  handler     = "processing.handle_request"
  policy = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:us-east-1:889332921058:table/avm-88eewe-appRequests"]
    }
  }
  env = {
    "DYNAMODB_TABLE" = module.serverless.dynamodb_table
  }
}

module "backend_archiving" {
  source = "../modules/lambda"

  name        = "backend_archiving"
  runtime     = "python3.7"
  code_source = "src/backend"
  handler     = "processing.archive_result"
  policy = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = ["arn:aws:dynamodb:us-east-1:889332921058:table/avm-88eewe-appRequests"]
    },
    kms = {
      effect    = "Allow",
      actions   = ["kms:*"],
      resources = ["arn:aws:kms:us-east-1:889332921058:*"]
    },
    s3 = {
      effect    = "Allow",
      actions   = ["s3:*"],
      resources = ["arn:aws:s3:::avm-serverless-4567/*"]
    }
  }
  env = {
    "ARCHIVE_BUCKET" = module.serverless.s3_bucket
    "DYNAMODB_TABLE" = module.serverless.dynamodb_table
  }
}

module "request_worker" {
  source = "../modules/lambda"

  name        = "request-worker"
  runtime     = "ruby2.7"
  code_source = "src/sqs-handle-item"
  handler     = "worker.triggerProcessing"
  policy = {
    sqs = {
      effect    = "Allow",
      actions   = ["sqs:*"],
      resources = ["arn:aws:sqs:us-east-1:889332921058:requestQueue"]
    },
    steps = {
      effect    = "Allow",
      actions   = ["states:*"],
      resources = ["arn:aws:states:us-east-1:889332921058:stateMachine:state_machine"]
    }
  }
  env = {
    "STATE_MACHINE_ARN" = module.step_function.state_machine_arn
  }
}

resource "aws_lambda_event_source_mapping" "request_worker_sqs_trigger" {
  event_source_arn = module.serverless.sqs_queue_arn
  function_name    = module.request_worker.arn
}

# module "api_gw" {
#   source = "../modules/api-gw"

#   handle_requests_lambda = module.handle_requests_lambda.arn
# }

module "api_gw_v1" {
  source = "../modules/api-gw-v1"

  lambda_invoke_arn = module.handle_requests_lambda.lambda_invoke_arn
  lambda_function_name = module.handle_requests_lambda.lambda_function_name
}

module "step_function" {
  source = "../modules/step"

  processing_lambda_arn = module.backend_processing.arn
  archiving_lambda_arn  = module.backend_archiving.arn
}
