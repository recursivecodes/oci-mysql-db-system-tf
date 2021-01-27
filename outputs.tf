output "public_ip" {
  description = "Public IPs of bastion host. "
  value       = oci_core_instance.compute_bastion_host[*].public_ip
}

output "private_ip" {
    description = "The Private IP of the MySQL DB System"
    value = oci_mysql_mysql_db_system.mysql_db_system.ip_address
}

output "mysql_user" {
    description = "The MySQL admin username"
    value = var.admin_username
}