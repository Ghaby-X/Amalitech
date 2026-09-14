resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-postgres"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-postgres" }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = false

  auto_minor_version_upgrade = true
  skip_final_snapshot        = true

  tags = { Name = "${var.project_name}-postgres" }
}
