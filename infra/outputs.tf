output "vcn_id" {
  value = module.network.vcn_id
}

output "api_subnet_id" {
  value = module.network.api_subnet_id
}

output "lb_subnet_id" {
  value = module.network.lb_subnet_id
}

output "workers_subnet_id" {
  value = module.network.workers_subnet_id
}

output "cluster_id" {
  value = module.oke.cluster_id
}

output "kubernetes_version" {
  value = module.oke.kubernetes_version
}

output "node_pool_id" {
  value = module.oke.node_pool_id
}

output "kubeconfig_path" {
  value = abspath(local_sensitive_file.kubeconfig.filename)
}

output "app_url" {
  value = "http://${coalesce(module.app.load_balancer_ip, "pending")}"
}
