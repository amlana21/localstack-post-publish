output "function_url" {
  description = "Function URL."
  value       = aws_lambda_function_url.lambda_function_url.function_url
}

output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.web_bucket.arn
}

output "name" {
  description = "id of the bucket"
  value       = aws_s3_bucket.web_bucket.id
}

output "domain" {
  description = "Domain name of the website"
  value       = aws_s3_bucket_website_configuration.web_bucket.website_domain
}

output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.web_bucket.website_endpoint
}