# Researches
Today's researches was about `Sealed Secrets` and the `CI/CD Pipeline` (for the next day, ill prepare the webapp or website dev)

# Installations
## 1. Helm repo
Again, like yesterday we add the helm repo of the app inside `/infrastructure/sources/` <br>
We create `sealed-secrets.yaml`:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: sealed-secrets
  namespace: flux-system
spec:
  interval: 1h
  url: https://bitnami-labs.github.io/sealed-secrets
```
We create a new `sealed-secrets` controller and `release.yaml` inside:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sealed-secrets
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: flux-system
spec:
  interval: 30m
  chart:
    spec:
      chart: sealed-secrets
      version: '>=2.0.0'
      sourceRef:
        kind: HelmRepository
        name: sealed-secrets
        namespace: flux-system
  targetNamespace: sealed-secrets
  install:
    createNamespace: true
```
And then we add it to the cluster inside `/clusters/k3s/flux-system/infrastructure.yaml`:
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-sealed-secrets
  namespace: flux-system
spec:
  interval: 10m
  path: infrastructure/sealed-secrets
  prune: true
  sourceRef:
    kind: GitRepository
    name: gitops-repo
  dependsOn:
    - name: infra-sources
```
## 2. We Push
```bash
git add *
git commit -m "the commit blablabla"
git pull --rebase
git push

# We make it so that flux see the new files
flux reconcile source git flux-system
flux reconcile kustomization infra-sources
flux reconcile kustomization infra-sealed-secrets
```
## 3. We install `kubeseal`:
```bash
sudo pacman -S kubeseal
```
## 4. We fetch the public key:
```bash
kubeseal --fetch-cert --controller-name=sealed-secrets-sealed-secrets --controller-namespace=sealed-secrets > sealed-secrets-pub.crt
```
## 5. We create the secret in local and encrypt it
```bash
kubectl create secret generic grafana-admin-password --from-literal=admin-user='admin' --from-literal=admin-password='redacted_xd' --namespace=monitoring --dry-run=client -o yaml > /tmp/grafana-secret.yaml
```
We can `cat` it to see the base64 of it<br>
And then we encrypt it:
```bash
kubeseal --format=yaml --cert=sealed-secrets-pub.crt --controller-name=sealed-secrets-sealed-secrets --controller-namespace=sealed-secrets < /tmp/grafana-secret.yaml > infrastructure/sealed-secrets/grafana-sealed-secret.yaml
```
And this one should be safe to commit to git, so we can delete the `/tmp/grafana-secret.yaml`
## 6. We edit the grafana "config"
We open `/infrastructure/monitoring/kube-prometheus-stack.yaml` and change `adminPassword` with:
```yaml
grafana:
  enabled: true
  adminUser: admin
  admin:
    existingSecret: grafana-admin-password
    userKey: admin-user
    passwordKey: admin-password
```
## 7. We push (and update the .gitignore)
new `.gitignore`:
```.gitignore
# Secrets and Keys
*.secret
*-secret.yaml
!*sealed-secret.yaml
.env
.secrets/
*.pem
*.key
!sealed-secrets-pub.crt

# Tokens
*token*
ghp_*

# Temp files
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
```
The push:
```bash
git add infrastructure/ .gitignore sealed-secrets-pub.crt
git commit -m "commit texte"
git push
```
We delete the old grafana to force the recreation if we messed up:
```bash
kubectl delete secret grafana-admin-password -n monitoring
```
We reconcile:
```bash
flux reconcile kustomization infra-sealed-secrets
flux reconcile kustomization infra-monitoring
```

And now we should be able to connect to the grafana dashboard with our new password
> [!Warning]
> But all of this **for grafana** is a bit useless since at the first login, they ask us to change the password, so even if the first password is in clear, the new one shouldn't be on the github, ill try to use it for the next part

## 8. Structure of the github repo
```bash
GitOps/
├── apps
│   ├── base
│   │   └── whoami
│   │       ├── deployment.yaml
│   │       └── kustomization.yaml
│   └── production
├── clusters
│   └── k3s
│       └── flux-system
│           ├── apps.yaml
│           ├── gotk-components.yaml
│           ├── gotk-sync.yaml
│           ├── infrastructure.yaml
│           ├── kustomization.yaml
│           └── sources.yaml
├── day
│   ├── day1.md
│   ├── day2.md
│   └── day3.md
├── infrastructure
│   ├── ingress
│   ├── monitoring
│   │   └── kube-prometheus-stack.yaml
│   ├── sealed-secrets
│   │   ├── grafana-sealed-secret.yaml
│   │   └── release.yaml
│   └── sources
│       ├── prometheus-community.yaml
│       └── sealed-secrets.yaml
├── README.md
├── scripts
│   └── debug_flux.sh
└── sealed-secrets-pub.crt
```
