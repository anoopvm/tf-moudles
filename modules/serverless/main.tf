variable "dynamodb_table" {
  type = string
  default = "avm-88eewe-appRequests"
}

variable "s3_bucket" {
  type = string
  default = "avm-serverless-4567"
}

variable "sqs_name" {
  type = string
  default = "requestQueue"
}

resource "aws_kms_key" "objects" {
  description             = "KMS key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.s3_bucket
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.objects.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning = {
    enabled = true
  }
}

module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"

  name = var.sqs_name
  tags = {
    Environment = "dev"
  }
}

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = var.dynamodb_table
  hash_key = "id"
  range_key = "requestID"

  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "requestID"
      type = "S"
    }
  ]

  # tags = {
  #   Terraform   = "true"
  #   Environment = "staging"
  # }
}

output "s3_bucket" {
  value = module.s3_bucket.s3_bucket_id
}

output "dynamodb_table" {
  value = module.dynamodb_table.dynamodb_table_id
}

output "sqs_queue_arn" {
  value = module.sqs.queue_arn
}

output "sqs_queue_name" {
  value = module.sqs.queue_name
}