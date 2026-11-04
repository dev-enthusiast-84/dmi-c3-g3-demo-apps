output "ec2_public_ip" {
  description = "Public IPv4 address of the EpicBook EC2 instance."
  value       = module.compute.public_ip
}

output "rds_endpoint" {
  description = "Connection endpoint (address:port) of the RDS MySQL instance. Reachable only from the EC2 instance."
  value       = module.database.rds_endpoint
}
