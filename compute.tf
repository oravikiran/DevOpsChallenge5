## Technical Challenge

data "template_file" "key_script" {
  template = file("./scripts/sshkey.tpl")
  vars = {
    ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  }
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "ainit.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.key_script.rendered
  }
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.A1.Flex",
    "VM.Optimized3.Flex"
  ]
}

# Checks if is using Flexible Compute Shapes
locals {
  is_flexible_node_shape = contains(local.compute_flexible_shapes, var.InstanceShape)
}

resource "oci_core_instance" "bastion_instance" {
  availability_domain = var.availablity_domain_name == "" ? data.oci_identity_availability_domains.ADs.availability_domains[0]["name"] : var.availablity_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "BastionVM"
  shape               = var.InstanceShape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.InstanceFlexShapeMemory
      ocpus = var.InstanceFlexShapeOCPUS
    }
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.vcn01_subnet_pub02.id
    display_name = "primaryvnic"
    assign_public_ip = true
    nsg_ids = [oci_core_network_security_group.SSHSecurityGroup.id]
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.InstanceImageOCID.images[0].id
    boot_volume_size_in_gbs = "50"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = data.template_cloudinit_config.cloud_init.rendered
  }

  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_instance" "tomcat-server" {
  count               = var.numberOfNodes
  availability_domain = var.availablity_domain_name == "" ? data.oci_identity_availability_domains.ADs.availability_domains[0]["name"] : var.availablity_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "tomcat-server-${count.index}"
  shape               = var.InstanceShape

  dynamic "shape_config" {
    for_each = local.is_flexible_node_shape ? [1] : []
    content {
      memory_in_gbs = var.InstanceFlexShapeMemory
      ocpus = var.InstanceFlexShapeOCPUS
    }
  }
  
  fault_domain        = "FAULT-DOMAIN-${(count.index%3)+1}"

  create_vnic_details {
    subnet_id = oci_core_subnet.vcn01_subnet_app01.id
    display_name = "primaryvnic"
    assign_public_ip = false
    nsg_ids = [oci_core_network_security_group.SSHSecurityGroup.id, oci_core_network_security_group.APPSecurityGroup.id]
  }

  source_details {
    source_type = "image"
    source_id   = lookup(data.oci_core_images.InstanceImageOCID.images[0], "id")
    boot_volume_size_in_gbs = "50"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = data.template_cloudinit_config.cloud_init.rendered
  }

  defined_tags = {"${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }

}

resource "grafana_folder" "collection" {
  title = "Monitoring Systems"
}

resource "grafana_data_source" "metrics" {
  type      	= "prometheus"
  name      	= "metricfire"
  url       	= "http://127.0.0.1:12345/"
}

resource "grafana_dashboard" "metrics" {
  config_json = file("metricfire-dashboard.json")
}
