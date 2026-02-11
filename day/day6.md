# Researches
I looked up `terraform` to automatically configure infrastructure via config files, and then configure it via `ansible`, which will help me recreate/reconfigure my homelab easily
> [!Warning]
> Since I run the GitOps inside a vm, and I do not want anything related to AWS/Azure for the moment, Ill just learn on my side and not push it onto the github repo, I do not see a real benefits of this for my homelab <br>

So instead, today im going to change the portforward of each apps to instead use `Traefik`
# Installation
## 1. Helm repo
Again, inside `/infrastructure/sources/` we create `traefik.yaml`:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: traefik
  namespace: flux-system
spec:
  interval: 1h
  url: https://traefik.github.io/charts
```
We create a new `traefik` controller and `release.yaml` inside:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: traefik
  namespace: flux-system
spec:
  interval: 30m
  chart:
    spec:
      chart: traefik
      version: '>=30.0.0'
      sourceRef:
        kind: HelmRepository
        name: traefik
        namespace: flux-system
  targetNamespace: traefik
  install:
    createNamespace: true
  values:
    service:
      type: NodePort
      nodePorts:
        web: 30081
        websecure: 30443
```
And then we add it to the cluster inside `/clusters/k3s/flux-system/infrastructure.yaml`:
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-traefik
  namespace: flux-system
spec:
  interval: 10m
  path: infrastructure/traefik
  prune: true
  sourceRef:
    kind: GitRepository
    name: gitops-repo
  dependsOn:
    - name: infra-sources
```
## 2. We push and deploy
```bash
git add infrastructure/sources/traefik.yaml infrastructure/traefik/ clusters/k3s/flux-system/infrastructure.yaml
git commit -m "the commit"
git push
# No need rebase this time since I didn't forgot to pull after the push of the day.md

# Then, the usual flux commands
flux reconcile source git flux-system
flux reconcile kustomization infra-sources
flux reconcile kustomization infra-sealed-secrets
```
## 3. Make it so, the host machine resolve the urls
We add to the `host` file:
```plaintexte
127.0.0.1 homepage.local
127.0.0.1 grafana.local
127.0.0.1 prometheus.local
127.0.0.1 traefik.local
```
## 4. We create the ingress for each services
Inside `/apps/base/homepage/` we create `ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: homepage
  namespace: homepage
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: homepage.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: homepage
            port:
              number: 80
```
And in the same folder, we add inside the `kustomization.yaml`: `- ingress.yaml` Under `- deployment.yaml` <br>
`cat` of the file:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - ingress.yaml
```
Then, inside `infrastructure/monitoring/` we create `grafana-ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: grafana.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: monitoring-kube-prometheus-stack-grafana
            port:
              number: 80
```
And then the prometheus image, we create `prometheus-ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: prometheus.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: monitoring-kube-prometheus-prometheus
            port:
              number: 9090
```
And for the Traefik dashboard, we create `infrastructure/traefik/dashboard-ingress.yaml`:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: traefik
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`traefik.local`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
```
Then, we create a `kustomization.yaml` to deploy in order:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - kube-prometheus-stack.yaml
  - grafana-ingress.yaml
  - prometheus-ingress.yaml
```
## 5. We update the links in the homepage
Inside `/homepage/index.html` we change the `<div class="services">` content to:
```html
<a href="http://grafana.local" class="service-link">grafana</a>
<a href="http://prometheus.local" class="service-link">prometheus</a>
<a href="http://traefik.local" class="service-link">traefik dashboard</a>
<a href="https://github.com/Shoukshai/GitOps" target="_blank" class="service-link">github</a>
```
## 6. We push everything
```bash
git add apps/base/homepage/ infrastructure/monitoring/ homepage/
git commit -m "commit"
git push

flux reconcile source git flux-system
flux reconcile kustomization apps
flux reconcile kustomization infra-monitoring

kubectl rollout restart deployment homepage -n homepage
```
## 7. Change the port forwarding vm's config
We deletes all the old rules (beside ssh) and add a new one with:<br>
`Host port`: 80
`Guest port`: 30081

And now we have clean url
## 8. Structure of the github repo
```bash
GitOps/
├── apps
│   ├── base
│   │   ├── homepage
│   │   │   ├── deployment.yaml
│   │   │   ├── ingress.yaml
│   │   │   └── kustomization.yaml
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
│   ├── day3.md
│   ├── day4.md
│   ├── day5.md
│   └── day6.md
├── homepage
│   ├── assets
│   │   └── background.png
│   ├── Dockerfile
│   ├── index.html
│   └── style.css
├── infrastructure
│   ├── ingress
│   ├── monitoring
│   │   ├── grafana-ingress.yaml
│   │   ├── kube-prometheus-stack.yaml
│   │   ├── kustomization.yaml
│   │   └── prometheus-ingress.yaml
│   ├── sealed-secrets
│   │   ├── grafana-sealed-secret.yaml
│   │   └── release.yaml
│   ├── sources
│   │   ├── prometheus-community.yaml
│   │   ├── sealed-secrets.yaml
│   │   └── traefik.yaml
│   └── traefik
│       ├── dashboard-ingress.yaml
│       └── release.yaml
├── README.md
├── scripts
│   └── debug_flux.sh
└── sealed-secrets-pub.crt
```
