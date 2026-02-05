# Random Origin Header Value
resource "random_password" "origin_header_value" {
  length  = 32
  special = false
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "liberdade_cf" {
  provider = aws.liberdade

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Liberdade Notes App"
  default_root_object = ""

  logging_config {
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "lab-3b"
    include_cookies = false
  }

  origin {
    domain_name = aws_lb.liberdade_alb.dns_name
    origin_id   = "liberdade-alb-origin"

    custom_header {
      name  = var.origin_header_name
      value = random_password.origin_header_value.result
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "liberdade-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = aws_cloudfront_cache_policy.caching_optimized.id # Temporary caching policy
    # cache_policy_id = aws_cloudfront_cache_policy.liberdade_no_cache.id                         # No-cache policy for dynamic content
    origin_request_policy_id = aws_cloudfront_origin_request_policy.liberdade_forward_qs.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-cf"
  })
}

# CloudFront policies 
# No-cache + forward query strings
resource "aws_cloudfront_cache_policy" "caching_optimized" {
  provider = aws.liberdade
  name     = "${local.liberdade_prefix}-caching-optimized"
  comment  = "Temporary caching policy – respects query strings for /add?note=..."

  min_ttl     = 0
  default_ttl = 300
  max_ttl     = 3600

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

# No-cache policy for dynamic content
# resource "aws_cloudfront_cache_policy" "liberdade_no_cache" {
#   provider = aws.liberdade
#   name     = "${local.liberdade_prefix}-no-cache"
#   comment  = "No caching – ensures dynamic content freshness"

#   min_ttl     = 0
#   default_ttl = 0
#   max_ttl     = 0

#   parameters_in_cache_key_and_forwarded_to_origin {
#     enable_accept_encoding_gzip   = false
#     enable_accept_encoding_brotli = false

#     cookies_config {
#       cookie_behavior = "none"
#     }

#     headers_config {
#       header_behavior = "none"
#     }

#     query_strings_config {
#       query_string_behavior = "all"
#     }
#   }
# }

resource "aws_cloudfront_origin_request_policy" "liberdade_forward_qs" {
  provider = aws.liberdade
  name     = "${local.liberdade_prefix}-forward-qs"
  comment  = "Forward query strings to origin for /add?note=..."

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}