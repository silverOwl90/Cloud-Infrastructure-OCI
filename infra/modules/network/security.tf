##############################################
# Security Lists (per-subnet firewall rules)
# Based on the OKE documentation for the Flannel CNI.
# Protocols: "6" = TCP, "1" = ICMP, "all" = all
##############################################

# ---------- Kubernetes API endpoint ----------
resource "oci_core_security_list" "api" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-sl-api"

  # kubectl from your machine
  ingress_security_rules {
    protocol    = "6"
    source      = var.api_allowed_cidr
    description = "Client access to the Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Workers talk to the control plane
  ingress_security_rules {
    protocol = "6"
    source   = var.workers_subnet_cidr
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.workers_subnet_cidr
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    protocol = "1"
    source   = var.workers_subnet_cidr
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Egress to Oracle services (OKE)
  egress_security_rules {
    protocol         = "6"
    destination      = local.osn_cidr
    destination_type = "SERVICE_CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Egress to the workers (kubelet, etc.)
  egress_security_rules {
    protocol    = "6"
    destination = var.workers_subnet_cidr
  }

  egress_security_rules {
    protocol    = "1"
    destination = var.workers_subnet_cidr
    icmp_options {
      type = 3
      code = 4
    }
  }
}

# ---------- Workers (private) ----------
resource "oci_core_security_list" "workers" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-sl-workers"

  # Node/pod traffic
  ingress_security_rules {
    protocol = "all"
    source   = var.workers_subnet_cidr
  }

  # Control plane -> workers
  ingress_security_rules {
    protocol = "6"
    source   = var.api_subnet_cidr
  }

  # Path MTU discovery
  ingress_security_rules {
    protocol = "1"
    source   = local.anywhere
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Load Balancer -> NodePorts
  ingress_security_rules {
    protocol    = "6"
    source      = var.lb_subnet_cidr
    description = "NodePorts from the Load Balancer"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  # Load Balancer -> kube-proxy health check
  ingress_security_rules {
    protocol = "6"
    source   = var.lb_subnet_cidr
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  # Unrestricted egress (goes through NAT or Service Gateway depending on the route)
  egress_security_rules {
    protocol    = "all"
    destination = local.anywhere
  }
}

# ---------- Load Balancers (public) ----------
resource "oci_core_security_list" "lb" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.prefix}-sl-lb"

  ingress_security_rules {
    protocol = "6"
    source   = local.anywhere
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = local.anywhere
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol    = "6"
    destination = var.workers_subnet_cidr
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  egress_security_rules {
    protocol    = "6"
    destination = var.workers_subnet_cidr
    tcp_options {
      min = 10256
      max = 10256
    }
  }
}
