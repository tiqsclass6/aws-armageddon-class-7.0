data "aws_iam_policy_document" "rds_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role for Shinjuku EC2 instances to access SSM and Secrets Manager
resource "aws_iam_role" "shinjuku_ssm_role" {
  provider           = aws.shinjuku
  name               = "shinjuku-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.rds_assume.json
}

# Attach AmazonSSMManagedInstanceCore policy to the Shinjuku SSM Role
resource "aws_iam_role_policy_attachment" "shinjuku_ssm_core" {
  provider   = aws.shinjuku
  role       = aws_iam_role.shinjuku_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create a Secrets Manager secret to store Shinjuku RDS credentials
resource "aws_secretsmanager_secret" "shinjuku_db_creds_v13" {
  provider    = aws.shinjuku
  name        = "lab-3b/shinjuku/rds/mysql_v13"
  description = "Authoritative DB credentials + endpoint for Lab 3B (Shinjuku only)"

  tags = merge(local.tags, {
    Name = "lab-3b-shinjuku-rds-creds-v13"
    Role = "authoritative"
  })
}

# Create a new version of the Secrets Manager secret with Shinjuku RDS credentials
resource "aws_secretsmanager_secret_version" "shinjuku_db_creds_v13" {
  provider  = aws.shinjuku
  secret_id = aws_secretsmanager_secret.shinjuku_db_creds_v13.id

  secret_string = jsonencode({
    username = var.shinjuku_db_username
    password = random_password.shinjuku_db_password.result
    engine   = var.shinjuku_db_engine
    host     = aws_db_instance.shinjuku.address
    port     = 3306
    dbname   = var.shinjuku_db_name
    region   = var.shinjuku_region
  })

  depends_on = [aws_db_instance.shinjuku]
}

# Store the Shinjuku RDS endpoint in SSM Parameter Store
resource "aws_ssm_parameter" "shinjuku_rds_endpoint" {
  provider    = aws.shinjuku
  name        = "/lab-3b/shinjuku/rds_endpoint"
  description = "RDS endpoint for Lab 3b (Shinjuku only)"
  type        = "SecureString"
  value       = aws_db_instance.shinjuku.address

  tags = merge(local.tags, {
    Name = "lab-3b-shinjuku-rds-endpoint"
  })
}