.PHONY: init plan apply destroy kubeconfig status fmt validate

# Terraform commands
init:
	cd live && terraform init

plan:
	cd live && terraform plan -out=tfplan

apply:
	cd live && terraform apply tfplan

destroy:
	cd live && terraform destroy

fmt:
	cd live && terraform fmt -recursive

validate:
	cd live && terraform validate

# Kubernetes commands
kubeconfig:
	aws eks update-kubeconfig --name litellm-eks --region ap-southeast-1

status:
	@echo "=== Nodes ==="
	kubectl get nodes
	@echo "\n=== LiteLLM Pods ==="
	kubectl get pods -n litellm
	@echo "\n=== Services ==="
	kubectl get svc -n litellm

logs:
	kubectl logs -n litellm -l app=litellm --tail=100 -f

port-forward-litellm:
	kubectl port-forward svc/litellm 4000:4000 -n litellm

port-forward-grafana:
	kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring

port-forward-argocd:
	kubectl port-forward svc/argocd-server 8080:443 -n argocd

# LiteLLM Admin API helpers
health:
	curl -s http://localhost:4000/health | jq .

models:
	curl -s http://localhost:4000/models | jq .

teams:
	curl -s http://localhost:4000/team/list \
		-H "Authorization: Bearer $${LITELLM_MASTER_KEY}" | jq .
