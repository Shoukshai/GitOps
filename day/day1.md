# Package list
```bash
sudo pacman -S curl git kubectl fluxcd ca-certificates openssh \
                    jq yq k9s bash-completion
```

curl -> k3s <br>
git -> for the GitOps <br>
kubectl -> talks to Kubernetes <br>
fluxcd -> main app to controle the cluster <br>
ca-certificates -> https <br>
openssh -> headless vm <br>
 <br>
jq -> json filter/reader <br>
yq -> same for yaml <br>
k9s -> manage cluster inside a TUI <br>
bash-completion -> just bash completion (normal arch package) <br>

```bash
sudo pacman -S helm terraform ansible docker docker-compose kubectx stern
```

helm -> kube package manager <br>
terraform -> Infrastructure as Code <br>
ansible -> auto config managment <br>
docker -> container <br>
docker-compose -> multi local container manager <br>
stern -> multi-pods logs <br>

# SSH
Enable ssh
```bash
sudo systemctl enable --now sshd
```
And just simply `ssh -p 2222 user@127.0.0.1` after adding port forwarding on virtualbox

# Start (Install [k3s](https://k3s.io/) & [flux](https://fluxcd.io/))
## 1. Installation of k3s
```bash
curl -sfL https://get.k3s.io | sh - 

# Check for Ready node, takes ~30 seconds 
sudo k3s kubectl get node

# Configure kubectl for local user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config

# Verify
kubectl get nodes
```

## 2. Bootstrap Flux for GitHub
```bash
export GITHUB_TOKEN="[redacted]"

# Bootstrap Flux
flux bootstrap github --token-auth --owner="Shoukshai" --repository="GitOps" --branch=main --path="clusters/k3s" --personal --timeout=15m

# Verify
flux check
flux get sources git
flux get kustomizations
```

## 3. Structure of the github repo
```bash
# Creation of the structure
mkdir -p infrastructure/{sources,monitoring,ingress}
mkdir -p apps/{base,production}
```

Tree :
```
GitOps/
├── clusters/
│   └── k3s/
│       ├── flux-system/
│       └── apps.yaml
├── infrastructure/
│   ├── sources/
│   ├── monitoring/
│   └── ingress/
└── apps/
    ├── base/
    │   └── whoami/
    │       ├── deployment.yaml
    │       └── kustomization.yaml
    └── production/
```

## 4. Whoami first app
Create an app inside the `/apps/base/` folder (whoami in this example)
Create then `deployment.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: whoami
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.10
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: whoami
spec:
  selector:
    app: whoami
  ports:
  - port: 80
    targetPort: 80
```
And then create `kustomization.yaml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```
And finnaly create `apps.yaml` inside `/clusters/k3s/`:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: gitops-apps
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/Shoukshai/GitOps
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 5m
  path: apps/base/whoami
  prune: true
  sourceRef:
    kind: GitRepository
    name: gitops-apps
```

## 5. Push
```bash
git add .
git commit -m "commit"
git push

flux reconcile source git gitops-apps
flux reconcile kustomization apps --with-source
# Flux should do that every 1 to 5 minutes aparently

# Verify
kubectl get pods -n whoami
kubectl get all -n whoami
```

## 6. Test
```bash
kubectl port-forward -n whoami svc/whoami 8080:80

# Inside another terminal
curl localhost:8080
```

## Usefull debugging commands that I needed 
```bash
# View flux logs
flux logs --kind=Kustomization --name=apps --follow

# View kube events
kubectl get events -n flux-system --sort-by='.lastTimestamp'

# TUI to explore the cluster
k9s

# Helped me find typo isse (used to verify yaml syntax)
yq eval apps/base/whoami/deployment.yaml
```

