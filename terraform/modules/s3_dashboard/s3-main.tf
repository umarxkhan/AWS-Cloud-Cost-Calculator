# ------------------------------
# S3 Bucket
# ------------------------------
resource "aws_s3_bucket" "dashboard" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# ------------------------------
# Block Public Access
# ------------------------------
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.dashboard.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------
# Enable Versioning
# ------------------------------
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.dashboard.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------
# Optional: Server-side Encryption
# ------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.dashboard.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------
# Upload Static Files
# ------------------------------
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/../../../dashboard", "**/*")

  bucket = aws_s3_bucket.dashboard.id
  key    = each.value
  source = "${path.module}/../../../dashboard/${each.value}"

  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "json" = "application/json"
  }, lower(try(split(".", each.value)[length(split(".", each.value)) - 1], "")), "application/octet-stream")
}

