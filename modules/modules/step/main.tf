variable "processing_lambda_arn" {
  type = string
}

variable "archiving_lambda_arn" {
  type = string
}


module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = "state_machine"
  definition = <<EOF
          {
            "StartAt": "ProcessRequest",
            "States": {
              "ProcessRequest": {
                "Type": "Task",
                "Resource": "${var.processing_lambda_arn}",
                "Next": "ArchiveResult"
              },
              "ArchiveResult": {
                "Type": "Task",
                "Resource": "${var.archiving_lambda_arn}",
                "End": true
              }
            }
          }
EOF

  service_integrations = {
    # dynamodb = {
    #   dynamodb = ["arn:aws:dynamodb:eu-west-1:052212379155:table/Test"]
    # }

    lambda = {
      lambda = [var.processing_lambda_arn, var.archiving_lambda_arn]
    }

    # stepfunction_Sync = {
    #   stepfunction = ["arn:aws:states:eu-west-1:123456789012:stateMachine:test1"]
    #   stepfunction_Wildcard = ["arn:aws:states:eu-west-1:123456789012:stateMachine:test1"]

    #   # Set to true to use the default events (otherwise, set this to a list of ARNs; see the docs linked in locals.tf
    #   # for more information). Without events permissions, you will get an error similar to this:
    #   #   Error: AccessDeniedException: 'arn:aws:iam::xxxx:role/step-functions-role' is not authorized to
    #   #   create managed-rule
    #   events = true
    # }
  }

  type = "STANDARD"

#   tags = {
#     Module = "my"
#   }
}

output "state_machine_arn" {
  value = module.step_function.state_machine_arn
}