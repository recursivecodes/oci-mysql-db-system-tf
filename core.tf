resource oci_core_instance compute_bastion_host {
  count = var.use_bastion_host ? 1 : 0
  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"
  }
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  availability_domain = var.availability_domain
  compartment_id = var.compartment_ocid
  create_vnic_details {
    assign_public_ip = "true"
    defined_tags = {}
    display_name = "mysql-bastion-host"
    freeform_tags = {}
    hostname_label = "mysql-bastion-host"
    nsg_ids = []
    private_ip = "10.0.0.2"
    skip_source_dest_check = "false"
    subnet_id = oci_core_subnet.public_subnet.id
  }
  defined_tags = {}
  display_name = "mysql-bastion-host"
  extended_metadata = {}
  fault_domain = "FAULT-DOMAIN-1"
  freeform_tags = {}
  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }
  launch_options {
    boot_volume_type = "PARAVIRTUALIZED"
    firmware = "UEFI_64"
    is_consistent_volume_naming_enabled = "true"
    network_type = "VFIO"
    remote_data_volume_type = "PARAVIRTUALIZED"
  }
  metadata = {
    "ssh_authorized_keys" = var.ssh_public_key
  }
  shape = var.shape
  source_details {
    source_id = var.image_id
    source_type = "image"
  }
  state = "RUNNING"
}

resource oci_core_internet_gateway internet_gateway {
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = "Internet Gateway MySQL VCN"
  enabled = "true"
  freeform_tags = {}
  vcn_id = oci_core_vcn.vcn.id
}

data oci_core_services core_services {

}

locals {
  all_services = [for service in data.oci_core_services.core_services.services : service if contains(regexall("All.*?",service.name), "All") && contains(regexall("Services In Oracle Services Network",service.name), "Services In Oracle Services Network")]
}

resource oci_core_service_gateway service_gateway {
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = "Service Gateway MySQL VCN"
  freeform_tags = {}
  services {
    service_id = local.all_services[0].id
  }
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_subnet private_subnet {
  cidr_block = "10.0.1.0/24"
  compartment_id = var.compartment_ocid
  defined_tags = {}
  dhcp_options_id = oci_core_vcn.vcn.default_dhcp_options_id
  display_name = "Private Subnet MySQL VCN"
  dns_label = "sub01251514401"
  freeform_tags = {}
  prohibit_public_ip_on_vnic = "true"
  route_table_id = oci_core_route_table.route_table.id
  security_list_ids = [
    oci_core_security_list.security_list_private.id,
  ]
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_subnet public_subnet {
  cidr_block = "10.0.0.0/24"
  compartment_id = var.compartment_ocid
  defined_tags = {}
  dhcp_options_id = oci_core_vcn.vcn.default_dhcp_options_id
  display_name = "Public Subnet MySQL VCN"
  dns_label = "sub01251514400"
  freeform_tags = {}
  prohibit_public_ip_on_vnic = "false"
  route_table_id = oci_core_vcn.vcn.default_route_table_id
  security_list_ids = [
    oci_core_vcn.vcn.default_security_list_id,
  ]
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_vcn vcn {
  cidr_blocks = [
    "10.0.0.0/16",
  ]
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = var.vcn_name
  dns_label = "mysqlvcn"
  freeform_tags = {}
}

resource oci_core_default_dhcp_options dhcp_options_for_vcn {
  defined_tags = {}
  display_name = "Default DHCP Options for MySQL VCN"
  freeform_tags = {}
  manage_default_resource_id = oci_core_vcn.vcn.default_dhcp_options_id
  options {
    custom_dns_servers = []
    server_type = "VcnLocalPlusInternet"
    type = "DomainNameServer"
  }
  options {
        search_domain_names = [
      "mysqlvcn.oraclevcn.com",
    ]
        type = "SearchDomain"
  }
}

resource oci_core_nat_gateway nat_gateway {
  block_traffic = "false"
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = "NAT Gateway MySQL VCN"
  freeform_tags = {}
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_route_table route_table {
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = "Route Table for Private Subnet MySQL VCN"
  freeform_tags = {}
  route_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
  route_rules {
    destination = "all-iad-services-in-oracle-services-network"
    destination_type = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_default_route_table default_route_table {
  defined_tags = {}
  display_name = "Default Route Table for MySQL VCN"
  freeform_tags = {}
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id
  route_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource oci_core_security_list security_list_private {
  compartment_id = var.compartment_ocid
  defined_tags = {}
  display_name = "Security List for Private Subnet MySQL VCN"
  egress_security_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol = "all"
    stateless = "false"
  }
  freeform_tags = {}
  ingress_security_rules {
    protocol = "6"
    source = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol = "1"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol = "1"
    source = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless = "false"
  }
  ingress_security_rules {
    description = "mysql"
    protocol = "6"
    source = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "3306"
      min = "3306"
    }
  }
  ingress_security_rules {
    description = "mysql"
    protocol = "6"
    source = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "33060"
      min = "33060"
    }
  }
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_default_security_list security_list_default {
  defined_tags = {}
  display_name = "Default Security List for MySQL VCN"
  egress_security_rules {
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol = "all"
    stateless = "false"
  }
  freeform_tags = {}
  ingress_security_rules {
    protocol = "6"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol = "1"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol = "1"
    source = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless = "false"
  }
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}