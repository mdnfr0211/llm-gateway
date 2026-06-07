module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # ArgoCD
  enable_argocd = true
  argocd = {
    namespace     = "argocd"
    chart_version = "9.5.18"
    values        = [file("${path.module}/../k8s/argocd-values.yaml")]
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    chart_version = "3.3.0"
    set = [
      {
        name  = "enableServiceMutatorWebhook"
        value = "false"
      },
      {
        name  = "controllerConfig.featureGates.ALBGatewayAPI"
        value = "true"
      }
    ]
  }

  enable_karpenter                  = true
  karpenter_enable_spot_termination = true
  karpenter = {
    repository_username = "AWS"
  }
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  enable_external_secrets = true
  external_secrets = {
    namespace = "external-secrets"
  }

  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    namespace = "monitoring"
    values = [yamlencode({
      grafana = {
        enabled       = true
        adminPassword = "admin"
        sidecar = {
          dashboards = {
            enabled = true
          }
        }
      }
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
        }
      }
    })]
  }
}

resource "kubectl_manifest" "gp3_storage_class" {
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "gp3"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner          = "ebs.csi.aws.com"
    volumeBindingMode    = "WaitForFirstConsumer"
    allowVolumeExpansion = true
    parameters = {
      type      = "gp3"
      encrypted = "true"
    }
  })

  depends_on = [
    module.eks_blueprints_addons
  ]
}
