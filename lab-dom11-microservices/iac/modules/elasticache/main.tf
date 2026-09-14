resource "aws_elasticache_serverless_cache" "this" {
  engine = "redis"
  name   = "${var.project_name}-redis"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.security_group_id]

  cache_usage_limits {
    data_storage {
      maximum = var.data_storage_max_gb
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = var.ecpu_per_second_max
    }
  }

  tags = { Name = "${var.project_name}-redis" }
}
