resource "kubectl_manifest" "gateway_api_crds" {
  for_each = toset([
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml",
  ])

  yaml_body = data.http.gateway_api_crds[each.key].response_body
}

resource "kubectl_manifest" "alb_gateway_class" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "amazon-alb"
    }
    spec = {
      controllerName = "gateway.k8s.aws/alb"
    }
  })

  depends_on = [kubectl_manifest.gateway_api_crds, module.eks_blueprints_addons]
}
