##############################################
# STEP 1: Network (VCN + gateways + subnets)
##############################################

# Oracle services (Object Storage, OCIR, etc.) for the Service Gateway
data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  osn_cidr = data.oci_core_services.all.services[0].cidr_block
  anywhere = "0.0.0.0/0"
}

# ---------- VCN ----------
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.prefix}-vcn"
  dns_label      = "${var.prefix}vcn"
}

# ---------- Gateways ----------
# Internet Gateway: inbound/outbound internet access for PUBLIC subnets
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-igw"
  enabled        = true
}

# NAT Gateway: outbound-only internet access for PRIVATE subnets
resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-nat"
}

# Service Gateway: private access to Oracle services (OCIR, Object Storage...)
resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-sgw"

  services {
    service_id = data.oci_core_services.all.services[0].id
  }
}

# ---------- Route tables ----------
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-rt-public"

  route_rules {
    destination       = local.anywhere
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-rt-private"

  route_rules {
    destination       = local.anywhere
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  route_rules {
    destination       = local.osn_cidr
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}
