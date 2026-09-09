# EFS-backed persistence for Postgres.

resource "aws_efs_file_system" "postgres" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = { Name = "${var.project_name}-postgres-efs" }
}

# One mount target per private subnet/AZ - each is an ENI that gives
# that AZ's tasks a local NFS endpoint to connect to.
resource "aws_efs_mount_target" "postgres" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.postgres.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}

# Scopes Postgres to its own directory on the filesystem
resource "aws_efs_access_point" "postgres" {
  file_system_id = aws_efs_file_system.postgres.id

  posix_user {
    uid = 70
    gid = 70
  }

  root_directory {
    path = "/postgres-data"

    creation_info {
      owner_uid   = 70
      owner_gid   = 70
      permissions = "0700"
    }
  }

  tags = { Name = "${var.project_name}-postgres-ap" }
}
