# Researches

Ive done some researches, and found about [helm-charts](https://github.com/prometheus-community/helm-charts) that contains `kube-prometheus-stack` which already contains everything I need for monitoring

# Installation for flux
## 1. Adding the "Helm repository source"

Inside `/infrastructure/sources/` we create the file `prometheus-community.yaml`:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: prometheus-community
  namespace: flux-system
spec:
  interval: 1h
  url: https://prometheus-community.github.io/helm-charts
```
Now inside `/infrastructure/monitoring/` we create the file `kube-prometheus-stack.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: kube-prometheus-stack
  namespace: flux-system
spec:
  interval: 30m
  chart:
    spec:
      chart: kube-prometheus-stack
      version: '>=65.0.0'
      sourceRef:
        kind: HelmRepository
        name: prometheus-community
        namespace: flux-system
      interval: 12h
  targetNamespace: monitoring
  install:
    createNamespace: true
    crds: CreateReplace
  upgrade:
    crds: CreateReplace
  values:
    grafana:
      enabled: true
      adminPassword: "admin"  # example password for the github, obviously we don't use that in real environments
      service:
        type: NodePort
        nodePort: 30080
      persistence:
        enabled: true
        size: 2Gi

    prometheus:
      prometheusSpec:
        retention: 7d
        storageSpec:
          volumeClaimTemplate:
            spec:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 2Gi
            cpu: 1000m
```

## 2. Then we connect everything to flux, we create `infrastructure.yaml` inside `/clusters/k3s/flux-system/`:
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-sources
  namespace: flux-system
spec:
  interval: 10m
  path: infrastructure/sources
  prune: true
  sourceRef:
    kind: GitRepository
    name: gitops-repo
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-monitoring
  namespace: flux-system
spec:
  interval: 10m
  path: infrastructure/monitoring
  prune: true
  sourceRef:
    kind: GitRepository
    name: gitops-repo
  dependsOn:
    - name: infra-sources
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: kube-prometheus-stack
      namespace: flux-system
```
## 3. Push
```bash
git pull --rebase
git add *
git commit -m "the commit blablabla"
git push

# We delete the old resources like gitops-apps se we centralize everything
kubectl delete gitrepository gitops-apps -n flux-system
kubectl delete gitrepository gitops-infra -n flux-system

# We make it so that flux see the new files
flux reconcile source git flux-system
flux reconcile kustomization flux-system --with-source
```

## 4. CLean the mess
```bahs
kubectl delete kustomization apps -n flux-system
kubectl delete kustomization infra-sources -n flux-system
kubectl delete kustomization infra-monitoring -n flux-system

flux reconcile source git flux-system
flux reconcile kustomization flux-system --with-source
```

And then grafana should be up, I added a port forward rule inside virtualbox since the vm is in NAR and not bridge <br>
Now I can acces grafana through `http://localhost:3000`

