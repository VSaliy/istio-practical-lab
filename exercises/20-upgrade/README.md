# Exercise 20: Revision-based Upgrade

## Difficulty
Advanced

## Estimated effort
90-180 minutes

## Learning objectives
- Upgrade Istio with a revisioned control plane.
- Migrate workloads by relabeling namespaces and restarting pods.
- Verify sidecar image versions and application traffic.
- Clean up old revisions and stale webhooks safely.

## Architectural context
Revision-based upgrades allow an old and new Istio control plane to run at the same time. Workloads move to the new revision only when their namespace label changes and the pods are restarted.

This lab starts from a revisioned install such as `1-24-2` and upgrades to a supported target revision such as `1-29-5` for Kubernetes `v1.31.2`.

## Prerequisites
- Exercises 01-19 completed.
- Bookinfo is healthy through ingress.
- `istioctl` for the target version is available.
- A target Istio version has been checked against the Kubernetes version support matrix.

## Files used
- `istio/installation/profiles/lab-profile.yaml`
- `exercises/20-upgrade/manifests/upgrade-validation-curl.yaml`

## Environment checks
```bash
kubectl get nodes -o wide
kubectl get pods -n istio-system
kubectl get ns bookinfo default --show-labels
istioctl version
curl -I http://172.22.0.240/productpage
```

Expected:
- nodes are `Ready`
- current Istio control plane is healthy
- Bookinfo returns `200`

## Implementation steps
Set the exact target version and revision. Do not use placeholders such as `1.25.x`.

```bash
export TARGET_ISTIO_VERSION=1.29.5
export TARGET_REVISION=1-29-5
```

Download the matching `istioctl`:

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${TARGET_ISTIO_VERSION}" TARGET_ARCH=x86_64 sh -
export PATH="$PWD/istio-${TARGET_ISTIO_VERSION}/bin:$PATH"
istioctl version --remote=false
```

Precheck and install the new revision:

```bash
istioctl x precheck
istioctl install -f istio/installation/profiles/lab-profile.yaml --set revision="${TARGET_REVISION}" -y
kubectl get deploy -n istio-system
```

Migrate namespaces:

```bash
kubectl label namespace bookinfo istio.io/rev="${TARGET_REVISION}" --overwrite
kubectl label namespace default istio.io/rev="${TARGET_REVISION}" --overwrite
```

Restart Bookinfo to reinject sidecars:

```bash
kubectl rollout restart deployment -n bookinfo
kubectl rollout status deployment -n bookinfo --timeout=300s
```

Verify sidecar versions:

```bash
kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].image}{"\n"}{end}'
curl -I http://172.22.0.240/productpage
```

Expected: every Bookinfo pod includes `docker.io/istio/proxyv2:1.29.5`.

## Cleanup old revision
Only after migrated workloads are healthy, remove the old revision:

```bash
istioctl uninstall --revision 1-24-2 -y
```

If old non-revisioned ambient or CNI components remain from previous exercises, remove only those specific workloads:

```bash
kubectl delete deployment istiod -n istio-system --ignore-not-found
kubectl delete daemonset ztunnel istio-cni-node -n istio-system --ignore-not-found
```

If stale non-revisioned webhooks point to a removed `istiod` service, delete only those stale webhooks:

```bash
kubectl delete validatingwebhookconfiguration istio-validator-istio-system --ignore-not-found
kubectl delete validatingwebhookconfiguration istiod-default-validator --ignore-not-found
kubectl delete mutatingwebhookconfiguration istio-revision-tag-default --ignore-not-found
kubectl delete mutatingwebhookconfiguration istio-sidecar-injector --ignore-not-found
```

Keep the target revision webhooks, for example:
- `istio-validator-1-29-5-istio-system`
- `istio-sidecar-injector-1-29-5`

## Expected output
```bash
kubectl get deploy -n istio-system
kubectl get pods -n istio-system
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"  "}{.spec.containers[*].image}{"\n"}{end}' | grep '1.24.2'
```

Expected:
- `istiod-1-29-5` remains
- old revision deployments are gone
- no `1.24.2` images are returned

## Verification
Apply a temporary curl pod to verify in-cluster service access:

```bash
kubectl apply -f exercises/20-upgrade/manifests/upgrade-validation-curl.yaml
kubectl wait --for=condition=Ready pod/upgrade-curl -n bookinfo --timeout=120s
kubectl exec -n bookinfo upgrade-curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" http://productpage:9080/productpage
```

Expected: `200`.

Run final checks:

```bash
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
kubectl get pods -A | grep -E 'Terminating|Error|CrashLoopBackOff|ImagePullBackOff'
```

## Failure experiments
Try applying an Istio resource while a stale validation webhook exists. The failure looks like:

```text
failed calling webhook "validation.istio.io": failed to call webhook: Post "https://istiod.istio-system.svc:443/validate": connect: connection refused
```

Fix by deleting only the stale non-revisioned webhook objects, not the new revisioned webhooks.

## Troubleshooting
- If `istioctl version` says Istio is not present but `istiod-1-29-5` exists, verify revisioned services and webhooks:

```bash
kubectl get svc -n istio-system
kubectl get mutatingwebhookconfiguration | grep 1-29-5
kubectl get validatingwebhookconfiguration | grep 1-29-5
```

- If sidecars are still old, confirm namespace labels and restart workloads.
- If ingress returns `503`, inspect Bookinfo endpoints and analyzer output.

## Cleanup
Remove the validation curl pod:

```bash
kubectl delete -f exercises/20-upgrade/manifests/upgrade-validation-curl.yaml --ignore-not-found
```

Do not downgrade during the lab. If rollback is required, relabel the namespace back to the old revision only if that old control plane still exists, then restart workloads.

## Architectural lessons
Revisioned upgrades reduce risk because application pods opt into the new data plane. The control-plane install is not the migration; workload reinjection is the migration.

## Production considerations
- Upgrade one namespace or workload group at a time.
- Confirm Kubernetes/Istio version compatibility before choosing the target.
- Keep rollback possible until smoke tests pass.
- Remove stale webhooks carefully.

## Self-assessment questions
1. Why does changing the namespace label not upgrade already-running pods?
2. Which commands prove that Bookinfo sidecars are on the target version?
3. Why is `--purge` risky when another Istio revision remains installed?
