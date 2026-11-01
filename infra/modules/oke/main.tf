##############################################
# STEP 2: OKE cluster + node pool
##############################################

data "oci_containerengine_cluster_option" "this" {
  cluster_option_id = "all"
  compartment_id    = var.compartment_ocid
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  available_versions = data.oci_containerengine_cluster_option.this.kubernetes_versions
  k8s_version        = coalesce(var.kubernetes_version, element(local.available_versions, length(local.available_versions) - 1))
}


resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_ocid
  name               = "${var.prefix}-oke"
  kubernetes_version = local.k8s_version
  vcn_id             = var.vcn_id
  type               = "BASIC_CLUSTER" # no charge for the control plane

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = var.api_subnet_id
  }

  options {
    service_lb_subnet_ids = [var.lb_subnet_id]

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

data "oci_containerengine_node_pool_option" "this" {
  node_pool_option_id = oci_containerengine_cluster.this.id
  compartment_id      = var.compartment_ocid
}

locals {
  is_arm      = length(regexall("\\.A[0-9]+\\.", var.node_shape)) > 0
  k8s_numeric = trimprefix(local.k8s_version, "v")

  # Oracle Linux OKE images matching the version and architecture, excluding GPU
  node_image_ids = [
    for s in data.oci_containerengine_node_pool_option.this.sources : s.image_id
    if length(regexall("^Oracle-Linux-.*-OKE-${local.k8s_numeric}-", s.source_name)) > 0
    && length(regexall("GPU", s.source_name)) == 0
    && (local.is_arm == (length(regexall("aarch64", s.source_name)) > 0))
  ]
}

resource "oci_containerengine_node_pool" "this" {
  compartment_id     = var.compartment_ocid
  cluster_id         = oci_containerengine_cluster.this.id
  name               = "${var.prefix}-pool"
  kubernetes_version = local.k8s_version
  node_shape         = var.node_shape
  ssh_public_key     = var.ssh_public_key

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gbs
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                = local.node_image_ids[0]
    boot_volume_size_in_gbs = var.node_boot_volume_gbs
  }

  node_config_details {
    size = var.node_count

    # Spread the nodes across all ADs in the region
    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.ads.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = var.workers_subnet_id
      }
    }

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  initial_node_labels {
    key   = "pool"
    value = "default"
  }

  lifecycle {
    precondition {
      condition     = length(local.node_image_ids) > 0
      error_message = "No node image found for ${local.k8s_version} and shape ${var.node_shape}."
    }
    ignore_changes = [node_source_details[0].image_id]
  }
}

data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id    = oci_containerengine_cluster.this.id
  token_version = "2.0.0"
  endpoint      = "PUBLIC_ENDPOINT"
}
