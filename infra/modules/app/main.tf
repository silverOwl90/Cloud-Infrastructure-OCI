##############################################
# STEP 3: Deploy the application with Helm
##############################################

resource "helm_release" "hello" {
  name             = "hello-app"
  chart            = "${path.module}/charts/hello-app" # local chart
  namespace        = var.namespace
  create_namespace = true

  # Override values from the chart's values.yaml
  values = [yamlencode({
    replicaCount = var.replicas
    message      = var.message
  })]

  wait    = true # wait until the pods are ready and the LB has an IP
  timeout = 900
}

# Read the Service to get the Load Balancer's public IP
data "kubernetes_service_v1" "hello" {
  metadata {
    name      = helm_release.hello.name
    namespace = var.namespace
  }
  depends_on = [helm_release.hello]
}
