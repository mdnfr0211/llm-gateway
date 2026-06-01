# LinkedIn Post

---

🚀 Just shipped: A production-grade LLM Gateway on AWS EKS

I built and open-sourced a complete reference architecture for deploying LiteLLM as an enterprise AI gateway:

✅ Multi-model routing via AWS Bedrock (Claude, Titan)
✅ AI guardrails — PII detection, credential blocking, medical compliance
✅ Full observability — Prometheus, Grafana, OpenSearch (SIEM)
✅ Auto-scaling — Karpenter for nodes, HPA for proxy pods
✅ Self-service team onboarding — budget controls + virtual keys

Tech stack:
• Terraform (public modules only, flat structure)
• EKS 1.31 + EKS Blueprints
• Aurora PostgreSQL + OpenSearch
• Gateway API + ALB Controller
• kube-prometheus-stack

The guardrails piece is particularly relevant for healthcare — blocking API keys, SSNs, and medical record numbers from being sent to LLMs in real-time.

Everything is Infrastructure as Code and deployable in a single `terraform apply`.

📖 Full write-up: [Medium article link]
💻 Source code: [GitHub link]

#AWS #Kubernetes #LLM #AI #DevOps #CloudArchitecture #Terraform #Observability #Healthcare #MLOps
