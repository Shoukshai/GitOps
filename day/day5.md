# CI/CD Pipeline
Today we built the CI/CD pipeline to automatically deploy our homepage.

# Nginx installation (with dockerfile)
## 1. We make the dockerfile by copying the static files to the nginx folder
```Dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
COPY assets/ /usr/share/nginx/html/assets/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```
## 2. We build and test
```bash
docker build -t homepage:test .

# To acces it on my host machin, same as grafana, I had to port forward on the vm
docker run -d -p 8000:80 --name homepage-test homepage:test

# And delete when it works
docker stop homepage-test
docker rm homepage-test
```
## 3. We make the GitHub action to build and push
We create the folder `.github/workflows/` and make `build-homepage.yaml` inside:
```yaml
name: Build and Push Homepage

on:
  push:
    branches:
      - main
    paths:
      - 'homepage/**'
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/homepage

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=raw,value=latest

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./homepage
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```
## 4. And then the kube manifests for the new app:
Inside `apps/base/` we create the folder `homepage` and inside `deployment.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: homepage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homepage
  namespace: homepage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: homepage
  template:
    metadata:
      labels:
        app: homepage
    spec:
      containers:
      - name: homepage
        image: ghcr.io/shoukshai/homepage:latest
        ports:
        - containerPort: 80
          resources:
            requests:
              memory: "32Mi"
              cpu: "50m"
            limits:
              memory: "64Mi"
              cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: homepage
  namespace: homepage
spec:
  selector:
    app: homepage
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30000
  type: NodePort
```
And then the `kustomization.yaml`
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```
## 5. Then we add the homepage to flux
We simply open the `clusters/k3s/flux-system/apps.yaml` and edit this line `path: apps/base/whoami` to be `path: apps/base` to deploy everything

## 6. Then we push and deploy
```bash
git add homepage/ apps/base/homepage/ .github/workflows/build-homepage.yaml clusters/k3s/flux-system
git commit -m "commit"
git push

flux reconcile source git flux-system
flux reconcile kustomization apps
```

(and I changed the port forwarding to 30000 guest port and added the prometheus port forwarding)
