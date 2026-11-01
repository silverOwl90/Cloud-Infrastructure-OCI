output "cluster_id" {
  value = oci_containerengine_cluster.this.id
}

output "kubernetes_version" {
  value = local.k8s_version
}

output "node_pool_id" {
  value = oci_containerengine_node_pool.this.id
}

output "kubeconfig" {
  description = "Cluster kubeconfig content"
  value       = data.oci_containerengine_cluster_kube_config.this.content
  sensitive   = true
}
