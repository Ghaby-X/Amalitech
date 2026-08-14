# key pair is shared across labs; managed in helpers/keypair
data "terraform_remote_state" "keypair" {
  backend = "s3"

  config = {
    bucket = "terraform-backend-eu-west-1-55zz0s"
    key    = "helpers/keypair/statefile"
    region = "eu-west-1"
  }
}
