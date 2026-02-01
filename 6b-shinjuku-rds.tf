# Random password for RDS instance
resource "random_password" "shinjuku_db_password" {
  length  = 24
  special = false
}

# RDS Subnet Group
resource "aws_db_subnet_group" "shinjuku" {
  provider   = aws.shinjuku
  name       = "${local.shinjuku_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.shinjuku_private[*].id

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-db-subnet-group"
  })
}

# RDS DB Instance
resource "aws_db_instance" "shinjuku" {
  provider          = aws.shinjuku
  identifier        = "${local.shinjuku_prefix}-rds"
  engine            = var.shinjuku_db_engine
  engine_version    = var.shinjuku_db_engine_version
  instance_class    = var.shinjuku_db_instance_class
  allocated_storage = var.shinjuku_db_allocated_storage
  db_name           = var.shinjuku_db_name
  username          = var.shinjuku_db_username
  password          = random_password.shinjuku_db_password.result

  db_subnet_group_name   = aws_db_subnet_group.shinjuku.name
  vpc_security_group_ids = [aws_security_group.shinjuku_rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false
  multi_az            = false

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-rds"
  })
}