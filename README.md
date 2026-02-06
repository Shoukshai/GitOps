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

# Start (Install [k3s](https://k3s.io/))
```
curl -sfL https://get.k3s.io | sh - 
# Check for Ready node, takes ~30 seconds 
sudo k3s kubectl get node
```
