output "jenkins" {
  value = aws_instance.jenkins
}
output "nexus" {
  value = aws_instance.nexus-ec2
}
output "sonarqube" {
  value = aws_instance.sonarqube-ec2
}