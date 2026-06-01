# All LiteLLM Kubernetes resources (namespace, secrets, ConfigMap, helm_release,
# Gateway API kubectl_manifests) have been migrated to ArgoCD + ESO.
# See live/argocd.tf for the ArgoCD Application and k8s/litellm/ for manifests.
#
# Pod Identity association for LiteLLM (Bedrock access) remains in irsa.tf.
#
# Before removing the old resources from Terraform state, run:
#   terraform state rm kubernetes_namespace.litellm
#   terraform state rm kubernetes_secret.litellm
#   terraform state rm kubernetes_secret.langfuse_litellm_keys
#   terraform state rm kubernetes_config_map.litellm_guardrails
#   terraform state rm helm_release.litellm
#   terraform state rm kubectl_manifest.litellm_target_group_config
#   terraform state rm kubectl_manifest.litellm_lb_config
#   terraform state rm kubectl_manifest.litellm_gateway
#   terraform state rm kubectl_manifest.litellm_httproute
