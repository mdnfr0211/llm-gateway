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
        adminPassword = "admin" # Change in production
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

  tags = {
    Environment = var.environment
    Project     = "litellm"
  }
}

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

data "http" "gateway_api_crds" {
  for_each = toset([
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml",
    "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml",
  ])

  url = each.key
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2023"
      role      = module.eks_blueprints_addons.karpenter.node_iam_role_name
      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
    }
  })

  depends_on = [module.eks_blueprints_addons]
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

  depends_on = [module.eks_blueprints_addons]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["c7i-flex.large", "m7i-flex.large"]
            }
          ]
        }
      }
      limits = {
        cpu    = "100"
        memory = "200Gi"
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
      }
    }
  })

  depends_on = [kubectl_manifest.karpenter_node_class]
}

resource "kubectl_manifest" "karpenter_node_class_litellm" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "litellm"
    }
    spec = {
      amiFamily = "AL2023"
      role      = module.eks_blueprints_addons.karpenter.node_iam_role_name
      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
    }
  })

  depends_on = [module.eks_blueprints_addons]
}

resource "kubectl_manifest" "karpenter_node_pool_litellm" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "litellm"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "workload" = "litellm"
          }
        }
        spec = {
          nodeClassRef = {
            name = "litellm"
          }
          taints = [{
            key    = "workload"
            value  = "litellm"
            effect = "NoSchedule"
          }]
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["c7i-flex.large", "m7i-flex.large"]
            }
          ]
        }
      }
      limits = {
        cpu    = "100"
        memory = "200Gi"
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
      }
    }
  })

  depends_on = [kubectl_manifest.karpenter_node_class_litellm]
}

resource "kubectl_manifest" "karpenter_node_class_langfuse" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "langfuse"
    }
    spec = {
      amiFamily = "AL2023"
      role      = module.eks_blueprints_addons.karpenter.node_iam_role_name
      subnetSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
      securityGroupSelectorTerms = [{
        tags = {
          "karpenter.sh/discovery" = var.cluster_name
        }
      }]
    }
  })

  depends_on = [module.eks_blueprints_addons]
}

resource "kubectl_manifest" "karpenter_node_pool_langfuse" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "langfuse"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "workload" = "langfuse"
          }
        }
        spec = {
          nodeClassRef = {
            name = "langfuse"
          }
          taints = [{
            key    = "workload"
            value  = "langfuse"
            effect = "NoSchedule"
          }]
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["c7i-flex.large", "m7i-flex.large"]
            }
          ]
        }
      }
      limits = {
        cpu    = "100"
        memory = "200Gi"
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
      }
    }
  })

  depends_on = [kubectl_manifest.karpenter_node_class_langfuse]
}
