##############################################
# STEP 1: Network (VCN + gateways + subnets)
##############################################
module "network" {
  source = "./modules/network"

  compartment_ocid    = var.compartment_ocid
  prefix              = var.prefix
  vcn_cidr            = var.vcn_cidr
  api_subnet_cidr     = var.api_subnet_cidr
  lb_subnet_cidr      = var.lb_subnet_cidr
  workers_subnet_cidr = var.workers_subnet_cidr
  api_allowed_cidr    = var.api_allowed_cidr
}

##############################################
# STEP 2: OKE cluster + node pool
##############################################
module "oke" {
  source = "./modules/oke"

  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  prefix           = var.prefix

  vcn_id            = module.network.vcn_id
  api_subnet_id     = module.network.api_subnet_id
  lb_subnet_id      = module.network.lb_subnet_id
  workers_subnet_id = module.network.workers_subnet_id

  kubernetes_version   = var.kubernetes_version
  node_shape           = var.node_shape
  node_ocpus           = var.node_ocpus
  node_memory_gbs      = var.node_memory_gbs
  node_count           = var.node_count
  node_boot_volume_gbs = var.node_boot_volume_gbs
  ssh_public_key       = var.ssh_public_key
}

resource "local_sensitive_file" "kubeconfig" {
  content         = module.oke.kubeconfig
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

##############################################
# STEP 3: Deploy the application with Helm
##############################################
module "app" {
  source = "./modules/app"

  namespace = var.namespace
  replicas  = var.replicas
  message   = var.message

  # Without ready nodes the pods stay Pending until the timeout
  depends_on = [module.oke]
}
