resource oci_mysql_mysql_db_system mysql_db_system {
  admin_password      = var.admin_password
  admin_username      = var.admin_username
  availability_domain = var.availability_domain
  backup_policy {
    freeform_tags = {}
    is_enabled        = "true"
    retention_in_days = "7"
    window_start_time = "00:00"
  }
  compartment_id = var.compartment_ocid
  data_storage_size_in_gb = var.mysql_db_size
  defined_tags = {}
  description  = "A MySQL DB System."
  display_name = var.mysql_db_name
  fault_domain = "FAULT-DOMAIN-1"
  freeform_tags = {}
  hostname_label = "mysql-db"
  ip_address  = "10.0.1.3"
  maintenance {
    window_start_time = "TUESDAY 07:52"
  }
  port = "3306"
  port_x  = "33060"
  shape_name = var.mysql_shape
  state = "ACTIVE"
  subnet_id = oci_core_subnet.private_subnet.id

  lifecycle {
    ignore_changes = [admin_password, admin_username]
  }
}

