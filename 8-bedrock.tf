# S3 bucket for report artifacts
resource "aws_s3_bucket" "bonus_g_ir_reports" {
  count  = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  bucket = var.bonus_g_reports_bucket_name != "" ? var.bonus_g_reports_bucket_name : "${var.project_name}-bonus-g-ir-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.tags, {
    Name = "${var.project_name}-bonus-g-ir-reports"
  })
}

resource "aws_s3_bucket_public_access_block" "bonus_g_ir_reports_block" {
  count                   = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  bucket                  = aws_s3_bucket.bonus_g_ir_reports[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bonus_g_ir_reports_sse" {
  count  = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  bucket = aws_s3_bucket.bonus_g_ir_reports[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM role/policy for Incident Reporter Lambda
resource "aws_iam_role" "bonus_g_incident_reporter_role" {
  count = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  name  = "${var.project_name}-bonus-g-incident-reporter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "bonus_g_incident_reporter_policy" {
  count = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  name  = "${var.project_name}-bonus-g-incident-reporter-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "LogsInsights",
        Effect = "Allow",
        Action = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:StopQuery",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents"
        ],
        Resource = "*"
      },

      # CloudWatch Alarms Permissions
      {
        Sid    = "CloudWatchRead",
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics"
        ],
        Resource = "*"
      },

      # SSM Parameter Permissions
      {
        Sid    = "SSMGet",
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "*"
      },

      # Secrets Manager Permissions
      {
        Sid      = "SecretsGet",
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = "*"
      },

      # KMS Permissions (if secrets are encrypted with KMS)
      {
        Sid      = "KMSDecrypt",
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = "*"
      },

      # Bedrock Invoke Permissions
      {
        Sid    = "BedrockInvoke",
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "*"
      },

      # S3 Write Reports Permissions
      {
        Sid    = "S3WriteReports",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.bonus_g_ir_reports[0].arn,
          "${aws_s3_bucket.bonus_g_ir_reports[0].arn}/*"
        ]
      },

      # SNS Publish Permissions (to publish to the existing incident topic)
      {
        Sid      = "SNSPublish",
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = "*"
      }
    ]
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "bonus_g_incident_reporter_attach" {
  count      = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  role       = aws_iam_role.bonus_g_incident_reporter_role[0].name
  policy_arn = aws_iam_policy.bonus_g_incident_reporter_policy[0].arn
}

# Lambda also needs basic execution role for CloudWatch Logs permissions
resource "aws_iam_role_policy_attachment" "bonus_g_lambda_basic_exec" {
  count      = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  role       = aws_iam_role.bonus_g_incident_reporter_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda packaging (zip handler.py)
data "archive_file" "bonus_g_incident_reporter_zip" {
  count       = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/incident_reporter"
  output_path = "${path.module}/lambda/incident_reporter.zip"
}

resource "aws_lambda_function" "bonus_g_incident_reporter" {
  count         = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  function_name = "${var.project_name}-bonus-g-incident-reporter"
  role          = aws_iam_role.bonus_g_incident_reporter_role[0].arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 512

  filename         = data.archive_file.bonus_g_incident_reporter_zip[0].output_path
  source_code_hash = data.archive_file.bonus_g_incident_reporter_zip[0].output_base64sha256

  environment {
    variables = {
      REPORT_BUCKET             = aws_s3_bucket.bonus_g_ir_reports[0].bucket
      APP_LOG_GROUP             = local.app_log_group
      WAF_LOG_GROUP             = local.waf_log_group
      SECRET_ID                 = local.secret_name
      SSM_PARAM_PATH            = "/lab/db/"
      SNS_TOPIC_ARN             = aws_sns_topic.db_incidents.arn
      BEDROCK_MODEL_ID_PRIMARY  = var.bonus_g_bedrock_model_id_primary
      BEDROCK_MODEL_ID_FALLBACK = var.bonus_g_bedrock_model_id_fallback

      # keep if your handler uses this already
      # BEDROCK_MODEL_ID = var.bonus_g_bedrock_model_id_primary

      # Optional knobs (if you later implement Mode A/B switching in code)
      FAST_WINDOW_MINUTES = "15"
      DEEP_WINDOW_MINUTES = "60"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.bonus_g_incident_reporter_attach,
    aws_iam_role_policy_attachment.bonus_g_lambda_basic_exec
  ]
}

# Subscribe Lambda to existing incident SNS topic
resource "aws_sns_topic_subscription" "bonus_g_incident_reporter_sub" {
  count     = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.bonus_g_incident_reporter[0].arn
}

# Grant SNS permission to invoke Lambda
resource "aws_lambda_permission" "bonus_g_allow_sns_invoke" {
  count         = var.enable_bonus_g_bedrock_auto_ir ? 1 : 0
  statement_id  = "AllowExecutionFromSNSBonusG"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bonus_g_incident_reporter[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.db_incidents.arn
}