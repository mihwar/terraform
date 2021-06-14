output "address" {
  value       = aws_db_instance.example.address
  description = "Connect to the dstabase at thid endpoint"
}

output "port" {
  value       = aws_db_instance.example.port
  description = "The port the database is listening on"
}
