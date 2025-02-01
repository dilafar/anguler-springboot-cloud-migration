output "public-ip-jenkins" {
  value = module.webserver.jenkins.public_ip
}

output "public-ip-nexus" {
  value = module.webserver.nexus.public_ip
}

output "public-ip-sonarqube" {
  value = module.webserver.sonarqube.public_ip
}

