output "load_balancer_ip" {
  value = try(data.kubernetes_service_v1.hello.status[0].load_balancer[0].ingress[0].ip, null)
}
