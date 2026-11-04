output "rds_endpoint" {
  description = "Connection endpoint of the RDS instance (address:port)."
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance, without the port."
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "Port the MySQL instance listens on."
  value       = aws_db_instance.mysql.port
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.main.name
}
