# Exercise 21: GitOps and CI/CD

## Difficulty
Advanced

## Estimated effort
90-180 minutes

## Learning objectives
- Understand the difference between CI validation and GitOps reconciliation.
- Install Argo CD into the lab cluster.
- Reconcile a small Bookinfo Istio configuration from Git.
- Create and repair controlled drift.
- Keep GitOps ownership scoped to lab-safe resources.

## Architectural context
GitOps makes Git the desired-state source for cluster configuration. A controller such as Argo CD continuously compares the live cluster state to the repository and reconciles differences.

This exercise uses Argo CD to manage only a small Bookinfo routing layer. It does not take ownership of the whole cluster or the full Bookinfo deployment installed by earlier exercises.

## Prerequisites
- Exercises 01-20 completed.
- Cluster is healthy.
- Bookinfo ingress returns `HTTP/1.1 200 OK`.
- The repository is pushed to a reachable Git remote if Argo CD will sync directly from GitHub.
- `bookinfo` namespace is labeled with the active Istio revision, for example `istio.io/rev=1-29-5`.

## Files used
- `exercises/21-gitops/apps/bookinfo/kustomization.yaml`
- `exercises/21-gitops/apps/bookinfo/bookinfo-gateway.yaml`
- `exercises/21-gitops/apps/bookinfo/bookinfo-virtualservice.yaml`
- `exercises/21-gitops/manifests/argocd-bookinfo-application.yaml`

## Environment checks
```bash
kubectl get nodes
kubectl get pods -A
kubectl get ns bookinfo --show-labels
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

Expected:
- nodes are `Ready`
- Bookinfo pods are `2/2 Running`
- analyzer has no Bookinfo errors
- ingress returns `200`

## Implementation steps
Install Argo CD:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl get pods -n argocd
```

Port-forward the UI if desired:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Update the Application manifest if your fork or branch differs:

```bash
kubectl apply -f exercises/21-gitops/manifests/argocd-bookinfo-application.yaml
```

Wait for reconciliation:

```bash
kubectl get application bookinfo-routing -n argocd
kubectl describe application bookinfo-routing -n argocd
kubectl get gateway,virtualservice -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Expected output
The Argo CD `Application` should become `Synced` and `Healthy`.

Bookinfo routing should exist:

```bash
kubectl get gateway bookinfo-gateway -n bookinfo
kubectl get virtualservice bookinfo -n bookinfo
```

Ingress should continue returning:

```text
HTTP/1.1 200 OK
```

## Drift experiment
Change the live `VirtualService` manually:

```bash
kubectl patch virtualservice bookinfo -n bookinfo --type=json \
  -p='[{"op":"replace","path":"/spec/http/0/route/0/destination/port/number","value":9081}]'
```

Check the app:

```bash
kubectl get application bookinfo-routing -n argocd
curl -I http://172.22.0.240/productpage
```

With automated sync and self-heal enabled, Argo CD should restore port `9080`. Verify:

```bash
kubectl get virtualservice bookinfo -n bookinfo -o jsonpath='{.spec.http[0].route[0].destination.port.number}{"\n"}'
curl -I http://172.22.0.240/productpage
```

Expected: `9080` and `HTTP/1.1 200 OK`.

## CI validation
This repository also has GitHub Actions workflows that validate lab assets:

```bash
ls .github/workflows
```

Relevant workflows include:
- Kubernetes validation
- Istio analysis
- YAML validation
- shell and PowerShell linting

CI checks pull requests before changes reach the GitOps controller. GitOps reconciles accepted desired state into the cluster.

## Verification
```bash
kubectl get application bookinfo-routing -n argocd
kubectl get gateway,virtualservice -n bookinfo
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Troubleshooting
- If Argo CD cannot reach the repo, verify `repoURL`, branch, and cluster egress.
- If the app is `OutOfSync`, describe it:

```bash
kubectl describe application bookinfo-routing -n argocd
```

- If validation fails, inspect the Istio objects:

```bash
kubectl get gateway bookinfo-gateway -n bookinfo -o yaml
kubectl get virtualservice bookinfo -n bookinfo -o yaml
istioctl analyze -n bookinfo
```

## Cleanup
Remove the GitOps application:

```bash
kubectl delete -f exercises/21-gitops/manifests/argocd-bookinfo-application.yaml --ignore-not-found
```

Leave Bookinfo routing in place if you want the lab app to continue working. If removing Argo CD completely:

```bash
kubectl delete namespace argocd --ignore-not-found
```

Verify Bookinfo:

```bash
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
CI and GitOps solve different problems. CI validates a proposed change. GitOps continuously reconciles accepted desired state. The smallest safe GitOps scope is better than immediately handing the controller the whole cluster.

## Production considerations
- Use separate Argo CD projects for teams or environments.
- Pin the Git target revision for controlled promotion.
- Protect the main branch.
- Review drift repair carefully before enabling broad automated self-heal.
- Avoid managing secrets in plaintext Git.

## Self-assessment questions
1. What changed when live drift was introduced?
2. Which object reconciled the drift back to Git state?
3. Why should GitOps ownership be scoped carefully?
