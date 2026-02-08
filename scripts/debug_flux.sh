#!/bin/bash

flux get sources git
flux get kustomizations

for kust in $(flux get kustomizations -o json | jq -r '.[] | select(.ready == false) | .name'); do
    [ -z "$kust" ] && continue
    flux logs --kind=Kustomization --name=$kust --tail=15
done

flux get helmreleases -A

kubectl get pods -A | grep -vE 'Running|Completed' | grep -v 'STATUS' || echo "All pods running"
kubectl get events -n flux-system --sort-by='.lastTimestamp' | tail -10
