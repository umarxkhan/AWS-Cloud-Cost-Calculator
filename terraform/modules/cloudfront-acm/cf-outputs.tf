output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.cf_distribution.domain_name
  description = "CloudFront domain (d123.cloudfront.net)"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.cf_distribution.arn
  description = "ARN of CloudFront distribution"
}

output "distribution_id" {
  value = aws_cloudfront_distribution.cf_distribution.id
}
