# EKS manifests

Deploys the same ShopNow app running on ECS to the `lab-dom11-shopnow-eks` cluster (`iac/modules/eks`), sharing the same RDS Postgres and ElastiCache Redis.

## 1. Point kubectl at the cluster

```bash
aws eks update-kubeconfig --name lab-dom11-shopnow-eks --region eu-west-1
kubectl get nodes   # both should show Ready
```

Authentication is via IAM - your AWS credentials need an EKS access entry on the cluster (Terraform grants one to whoever applies the `eks` module, via `aws_eks_access_entry` + `AmazonEKSClusterAdminPolicy`).

## 2. Install the AWS Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system -f lb-controller-values.yaml
```

`lb-controller-values.yaml` points the chart at the cluster name, VPC ID, and the IRSA role ARN Terraform already created (`module.eks.lb_controller_role_arn`). Confirm both controller pods reach `1/1 Running` before continuing - if they crash-loop, the IRSA trust policy or role is misconfigured.

## 3. Create the app secret

Pulls the real values from SSM (Terraform-generated) at creation time - never written to a file or printed:

```bash
kubectl create secret generic shopnow-secrets \
  --from-literal=postgres-password=$(aws ssm get-parameter --name /lab-dom11-shopnow/postgres/password --with-decryption --query Parameter.Value --output text --region eu-west-1) \
  --from-literal=frontend-secret-key=$(aws ssm get-parameter --name /lab-dom11-shopnow/frontend/secret-key --with-decryption --query Parameter.Value --output text --region eu-west-1)
```

## 4. Deploy

```bash
kubectl apply -f postgres-service.yaml -f redis-service.yaml -f backend.yaml -f frontend.yaml -f ingress.yaml
```

## 5. Verify

```bash
kubectl get pods
kubectl get ingress shopnow   # wait for ADDRESS to populate (1-3 min)
curl http://<ADDRESS>/
```

## Files

| File | What it is |
|---|---|
| `lb-controller-values.yaml` | Helm values for the AWS Load Balancer Controller install (step 2) |
| `postgres-service.yaml` / `redis-service.yaml` | `ExternalName` Services - DNS aliases to the real RDS/ElastiCache endpoints, no pods |
| `backend.yaml` / `frontend.yaml` | Deployment + Service for each app component. No `imagePullSecrets` - the EKS node IAM role already has ECR pull rights. `PGPASSWORD`/`SECRET_KEY` come from the `shopnow-secrets` Secret via `secretKeyRef`. |
| `ingress.yaml` | Routes `/` to `shopnow-frontend`; the AWS Load Balancer Controller turns this into a real ALB |

## Notes

- Images are the exact same ECR tag already running on ECS - same build, two platforms, for a fair comparison.
- Secret env vars are frozen at pod start (`secretKeyRef` reads once, not live-updating) - rotate a secret and you need `kubectl rollout restart deployment/backend` to pick it up.
- Resiliency demo: `kubectl delete pod <name>` - the Deployment's ReplicaSet notices and schedules a replacement automatically, same idea as ECS's service scheduler.
