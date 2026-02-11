Before going to bed, I was searching for best practices, and aparently forgot to clean the old NodePort<br>
So in order:
Edit `/infrastructure/monitoring/kube-prometheus-stack.yaml`:
```yaml
service:
  type: ClusterIP
# and delete the "nodePort: 30080"
```
And inside the same file:
```yaml
prometheus:
  type: ClusterIP
# and delete the "nodePort: 30090" aswell
```
Then inside `/apps/base/homepage/deployment.yaml`:
```yaml
type: ClusterIP
# We change the type and delete the line above "nodePort: 30000"
```
And we push and deploy...
```bash
git add *
git commit -m "fixed..."
git push

flux reconcile source git flux-system
flux reconcile kustomization apps
flux reconcile kustomization infra-monitoring
```
