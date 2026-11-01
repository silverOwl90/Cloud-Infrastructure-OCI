output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "api_subnet_id" {
  value = oci_core_subnet.api.id
}

output "lb_subnet_id" {
  value = oci_core_subnet.lb.id
}

output "workers_subnet_id" {
  value = oci_core_subnet.workers.id
}
