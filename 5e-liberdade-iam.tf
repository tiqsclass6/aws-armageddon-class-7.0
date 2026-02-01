data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "liberdade_read_db_metadata" {
  statement {
    sid       = "DescribeTags"
    actions   = ["ec2:DescribeTags"]
    resources = ["*"]
  }

  statement {
    sid       = "CloudFrontGetDistribution"
    actions   = ["cloudfront:GetDistribution"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "liberdade_read_db_secret" {
  statement {
    sid = "ReadShinjukuSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.shinjuku_db_creds_v9.arn
    ]
  }
}

# IAM Role for EC2 Instances
resource "aws_iam_role" "liberdade_ec2_role" {
  provider           = aws.liberdade
  name               = "liberdade-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# IAM Policies for EC2 Role
resource "aws_iam_policy" "liberdade_read_db_secret" {
  provider = aws.liberdade
  name     = "liberdade-read-shinjuku-db-secret"
  policy   = data.aws_iam_policy_document.liberdade_read_db_secret.json
}

resource "aws_iam_policy" "liberdade_read_db_metadata" {
  provider = aws.liberdade
  name     = "liberdade-read-shinjuku-db-metadata"
  policy   = data.aws_iam_policy_document.liberdade_read_db_metadata.json
}

# Attach Policies to Role
resource "aws_iam_role_policy_attachment" "liberdade_read_db_secret_attach" {
  provider   = aws.liberdade
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = aws_iam_policy.liberdade_read_db_secret.arn
}

resource "aws_iam_role_policy_attachment" "liberdade_read_db_metadata_attach" {
  provider   = aws.liberdade
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = aws_iam_policy.liberdade_read_db_metadata.arn
}

resource "aws_iam_role_policy_attachment" "liberdade_ssm_core" {
  provider   = aws.liberdade
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "liberdade_cw_agent" {
  provider   = aws.liberdade
  role       = aws_iam_role.liberdade_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile for EC2 Instances
resource "aws_iam_instance_profile" "liberdade_ec2_profile" {
  provider = aws.liberdade
  name     = "liberdade-ec2-profile"
  role     = aws_iam_role.liberdade_ec2_role.name
}