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
```bash
curl -sfL https://get.k3s.io | sh - 
# Check for Ready node, takes ~30 seconds 
sudo k3s kubectl get node

flux bootstrap github --token-auth --owner="Shoukshai" --repository="GitOps" --branch=main --path="clusters/k3s" --personal --timeout=15m
```

