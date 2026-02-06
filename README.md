# Package list
```bash
sudo pacman -S curl git kubectl fluxcd ca-certificates openssh \
                    jq yq k9s bash-completion
```

curl -> k3s
git -> for the GitOps
kubectl -> talks to Kubernetes
fluxcd -> main app to controle the cluster
ca-certificates -> https
openssh -> headless vm

jq -> json filter/reader
yq -> same for yaml
k9s -> manage cluster inside a TUI
bash-completion -> just bash completion (normal arch package)
