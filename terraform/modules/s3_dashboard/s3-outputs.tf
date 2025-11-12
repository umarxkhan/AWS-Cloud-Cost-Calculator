output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.dashboard.bucket
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.dashboard.bucket_regional_domain_name
}

output "bucket_arn" {
  value = aws_s3_bucket.dashboard.arn
}
