terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.11.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }

  

}

provider "aws" {
  region = "us-east-1"
}




data "aws_caller_identity" "current" {}

# ------------------role
data "aws_iam_policy_document" "samplesvc-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "samplesvc_lambda_access" {
  statement {
    actions   = ["logs:*","s3:*","dynamodb:*","cloudwatch:*","sns:*","lambda:*","secretsmanager:*","ds:*","ec2:*","lex:*"]
    effect   = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "samplesvclambdarole" {
    name               = "sample_role"
    assume_role_policy = data.aws_iam_policy_document.samplesvc-assume-role-policy.json
    inline_policy {
        name   = "policy-867530231"
        policy = data.aws_iam_policy_document.samplesvc_lambda_access.json
    }

}

# --------------lambda
resource "aws_lambda_function" "samplesvc_lambda" {
  function_name = "samplesvc_lambda"
  role          = aws_iam_role.samplesvclambdarole.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.9"
  filename      = "app.zip"
  source_code_hash = filebase64sha256("app.zip")
  timeout       = 60
  memory_size   = 128
}

resource "aws_lambda_function_url" "lambda_function_url" {
  function_name      = aws_lambda_function.samplesvc_lambda.arn
  authorization_type = "NONE"
  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}


# ---------------dynamodb
resource "aws_dynamodb_table" "users_table" {
  name           = "users"
  billing_mode   = "PROVISIONED"
  read_capacity = 1
  write_capacity = 1
  hash_key       = "rowid"
  attribute {
    name = "rowid"
    type = "S"
  }
}


# ---------------sample rows
resource "aws_dynamodb_table_item" "user1" {
  table_name = aws_dynamodb_table.users_table.name
  hash_key   = aws_dynamodb_table.users_table.hash_key

  item = <<ITEM
{
  "rowid": {"S": "1"},
  "username": {"S": "johndoe"},
  "userstatus": {"S": "Active"}
}
ITEM
}

resource "aws_dynamodb_table_item" "user2" {
  table_name = aws_dynamodb_table.users_table.name
  hash_key   = aws_dynamodb_table.users_table.hash_key

  item = <<ITEM
{
  "rowid": {"S": "2"},
  "username": {"S": "janedoe"},
  "userstatus": {"S": "Inactive"}
}
ITEM
}

resource "aws_dynamodb_table_item" "user3" {
  table_name = aws_dynamodb_table.users_table.name
  hash_key   = aws_dynamodb_table.users_table.hash_key

  item = <<ITEM
{
  "rowid": {"S": "3"},
  "username": {"S": "bobsmith"},
  "userstatus": {"S": "Active"}
}
ITEM
}



# s3 bucket with website hosting
resource "aws_s3_bucket" "web_bucket" {
  bucket = "<bucket_name>"
}

resource "aws_s3_bucket_website_configuration" "web_bucket" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}


resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "web_bucket_ownership" {
  bucket = aws_s3_bucket.web_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "web_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.web_bucket_ownership]

  bucket = aws_s3_bucket.web_bucket.id
  acl    = "public-read"
}


data "aws_iam_policy_document" "allow_access_public" {
  statement {
    effect = "Allow"

    principals {
      type = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.web_bucket.arn,
      "${aws_s3_bucket.web_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  acl          = "public-read"
  source_hash = filemd5("index.html")
  depends_on = [aws_s3_bucket_ownership_controls.web_bucket_ownership,aws_s3_bucket_public_access_block.allow_public,aws_s3_bucket_acl.web_acl]
}


