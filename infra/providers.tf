provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Connection details taken from the kubeconfig exposed by the oke module
locals {
  kubeconfig  = yamldecode(module.oke.kubeconfig)
  k8s_host    = local.kubeconfig.clusters[0].cluster.server
  k8s_ca_cert = base64decode(local.kubeconfig.clusters[0].cluster["certificate-authority-data"])
  # Fixed command/args (not from the kubeconfig): if the cluster doesn't exist yet
  # the kubeconfig is unknown at plan time and the kubernetes provider fails
  k8s_exec_cmd = "oci"
  k8s_exec_arg = ["ce", "cluster", "generate-token", "--cluster-id", module.oke.cluster_id, "--region", var.region]

  # The oci CLI signs the token with these credentials (the same as the oci provider)
  # instead of the ones in ~/.oci/config
  k8s_exec_env = {
    OCI_CLI_TENANCY     = var.tenancy_ocid
    OCI_CLI_USER        = var.user_ocid
    OCI_CLI_FINGERPRINT = var.fingerprint
    OCI_CLI_KEY_FILE    = var.private_key_path
    OCI_CLI_REGION      = var.region
  }
}

provider "kubernetes" {
  host                   = local.k8s_host
  cluster_ca_certificate = local.k8s_ca_cert

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = local.k8s_exec_cmd
    args        = local.k8s_exec_arg
    env         = local.k8s_exec_env
  }
}

provider "helm" {
  kubernetes = {
    host                   = local.k8s_host
    cluster_ca_certificate = local.k8s_ca_cert

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = local.k8s_exec_cmd
      args        = local.k8s_exec_arg
      env         = local.k8s_exec_env
    }
  }
}