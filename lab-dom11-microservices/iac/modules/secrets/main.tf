# Resources to generate passwords in secret manager
resource "random_password" "postgres" {
  length  = 24
  special = false
}

resource "random_password" "redis" {
  length  = 24
  special = false
}

resource "random_password" "frontend_secret_key" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "postgres_password" {
  name  = "/${var.project_name}/postgres/password"
  type  = "SecureString"
  value = random_password.postgres.result

  tags = { Name = "${var.project_name}-postgres-password" }
}

resource "aws_ssm_parameter" "redis_password" {
  name  = "/${var.project_name}/redis/password"
  type  = "SecureString"
  value = random_password.redis.result

  tags = { Name = "${var.project_name}-redis-password" }
}

resource "aws_ssm_parameter" "frontend_secret_key" {
  name  = "/${var.project_name}/frontend/secret-key"
  type  = "SecureString"
  value = random_password.frontend_secret_key.result

  tags = { Name = "${var.project_name}-frontend-secret-key" }
}
