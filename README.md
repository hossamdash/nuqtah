# Nuqtah

A simple Node.js "Hello World" HTTP server, containerized and deployed to a local k3s cluster via a GitOps CI/CD pipeline.

## Architecture

```
GitHub push (tag) ──► GitHub Actions ──► Docker Hub  
                                       │
                                       └──► Commit updated image tag in `values.yaml` to `main`
                                                        │
                                                        ▼
                                                  ArgoCD (k3s)
                                                        │
                                                        └──► Sync Helm chart ──► `nuqtah` Pod
```

**Stack:**

- **App** – Node.js HTTP server (`index.js`)
- **Container** – Docker, image pushed to Docker Hub
- **Kubernetes** – k3s (local lightweight cluster)
- **GitOps** – ArgoCD (auto-sync, self-heal)
- **Helm chart** – generic-app chart in `devops/helm/charts/generic-app/`
- **IaC** – Terraform (kubectl + helm providers) for ArgoCD install + ArgoCD Application manifest
- **State backend** – S3 via [Kumo](https://github.com/sivchari/kumo) (lightweight AWS emulator, runs locally on port 4566)
- **CI/CD** – GitHub Actions

---

## Prerequisites

| Tool | Version |
|------|---------|
| k3s | any recent |
| Docker | any recent |
| Terraform | ≥ 1.10 |
| AWS CLI | any recent |
| `yq` | v4+ |
| Node.js | 22 |

---

## Setup & Deployment

### 1. Clone and install JS dependencies

```bash
git clone git@github.com:hossamdash/nuqtah.git
cd nuqtah
npm install
```

### 2. Add GitHub secrets / variables

In your GitHub repo → **Settings → Secrets and variables → Actions**:

| Type | Name | Value |
|------|------|-------|
| Variable | `DOCKERHUB_USERNAME` | your Docker Hub username |
| Secret | `DOCKERHUB_TOKEN` | your Docker Hub access token |

### 3. Bootstrap the local environment

This script starts k3s, launches Kumo (local AWS emulator), and creates the S3 bucket used for Terraform state.

```bash
cd devops/terraform
chmod +x bootstrap.sh
./bootstrap.sh
```

### 4. Configure your repos in Terraform

Open `devops/terraform/k8s/argocd_apps.tf` and update the `locals` block with your GitHub owner and repo names:

```hcl
locals {
  apps = {
    nuqtah = {
      repo                 = "<your-repo-name>"
      owner                = "<your-github-username>"
      kubernetes_namespace = "nuqtah"
    }
  }
}
```

### 5. Apply Terraform

```bash
cd devops/terraform/k8s
terraform init
terraform apply
```

After `apply`, retrieve the SSH public keys that ArgoCD uses to pull each repo:

```bash
terraform output argocd_deploy_keys_public
```

### 6. Add the deploy key to GitHub

Copy the output from step 4 and add it as a **read-only Deploy Key** in:
`GitHub repo → Settings → Deploy keys → Add deploy key`

ArgoCD will now be able to clone the repo and sync the Helm chart.

### 7. Trigger the CI/CD pipeline

Tag a commit to kick off the full pipeline (lint → build → push → deploy):

```bash
git tag v1.0
git push origin v1.0
```

The pipeline will:

1. Run ESLint on the code
2. Build and push `hossamdash/nuqtah:v1.0` (and `:latest`) to Docker Hub
3. Update `devops/helm/apps/nuqtah/values.yaml` with the new tag and push back to `main`
4. ArgoCD detects the change and rolls out the new image automatically

### 8. Access the app

```bash
# Add nuqtah.local to /etc/hosts pointing at your k3s node IP
# Then:
curl http://nuqtah.local
# Hello Node!

# Or port-forward directly:
kubectl port-forward -n nuqtah svc/nuqtah 3000:3000
curl http://localhost:3000
# Hello Node!
```

---

## CI/CD Pipelines

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `nuqtah-lint.yaml` | PR to `main` | Runs ESLint (fast feedback) |
| `nuqtah-ci.yaml` | Push tag `v*.*` or manual | Lint → Build & push Docker image → Update values.yaml tag (GitOps CD) |

---

## Local Development

```bash
# Run the app
npm start

# Lint
npm run lint

# Build the Docker image locally
docker build -t nuqtah:local .

# Run the Docker image locally
docker run -p 3000:3000 nuqtah:local
```

---

## Assumptions

- **k3s is pre-installed** on the local machine (k3s kubeconfig at `/etc/rancher/k3s/k3s.yaml`).
- **Docker is running** for Kumo and local image builds.
- The GitHub repo is either public or a read-only deploy key is added after `terraform apply`.
- A single-node k3s setup is sufficient for this assessment; no multi-AZ or HA configuration is needed.
- Traefik (bundled with k3s) is used as the ingress controller — no annotation changes are needed.
- No secret management infrastructure (External Secrets Operator, Secrets Manager) is required since the app has no runtime secrets.
- Terraform state is stored in Kumo S3 (local). For production, replace Kumo with a real S3 bucket and remove the `skip_*` flags.

---

## Observability — New Relic

New Relic is used for **log collection only**. it's configured via a helm chart in the `k8s/templates/new-relic-values.yaml` file, which is rendered by Terraform with the license key injected at deploy time.

### Secret management

The New Relic license key is supplied as a Terraform variable via the environment. A `.envrc` file at `devops/terraform/k8s/.envrc` exports it as `TF_VAR_NEWRELIC_LICENSE_KEY`, which Terraform automatically picks up as `var.NEWRELIC_LICENSE_KEY`.

`.envrc` is **git-ignored** (`devops/terraform/k8s/.gitignore`), so the real key is never committed. Use [direnv](https://direnv.net/) for automatic loading, or source it manually before running Terraform.

### Deploy

```bash
cd devops/terraform/k8s

# Option A — direnv (auto-sources .envrc on cd)
# Option B — manual
source .envrc   # exports TF_VAR_NEWRELIC_LICENSE_KEY

terraform init && terraform apply

# Trigger the CI/CD pipeline so the app is deployed and starts generating logs
cd ../../..
git tag v<version>
git push origin v<version>
```
