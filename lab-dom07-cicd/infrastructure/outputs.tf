output "jenkins_public_ip" {
  value       = module.jenkins.public_ip
  description = "Public IP of the Jenkins host"
}

output "jenkins_public_dns" {
  value       = module.jenkins.public_dns
  description = "Public DNS of the Jenkins host"
}

output "jenkins_url" {
  value       = "http://${module.jenkins.public_dns}:8080"
  description = "Jenkins web UI URL"
}

output "deploy_public_ip" {
  value       = module.deploy_target.public_ip
  description = "Public IP of the deploy target - use as the Jenkinsfile's DEPLOY_HOST parameter"
}

output "deploy_public_dns" {
  value       = module.deploy_target.public_dns
  description = "Public DNS of the deploy target"
}

output "app_url" {
  value       = "http://${module.deploy_target.public_dns}:${var.app_port}"
  description = "URL to verify the deployed app"
}

output "ssh_user" {
  value       = "ec2-user"
  description = "SSH user for both instances (Amazon Linux default)"
}

output "key_name" {
  value       = data.terraform_remote_state.keypair.outputs.key_name
  description = "Name of the AWS key pair (shared across labs, managed in helpers/keypair)"
}

output "private_key_path" {
  value       = data.terraform_remote_state.keypair.outputs.private_key_path
  description = "Local path to the private key - paste its contents into the Jenkins ec2_ssh credential"
}
