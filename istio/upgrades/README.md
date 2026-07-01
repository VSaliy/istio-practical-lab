# Upgrades

This layer documents the revision-based Istio upgrade path used by `exercises/20-upgrade`.

## Choose a target version

Use an exact Istio version, not a placeholder:

```bash
export TARGET_ISTIO_VERSION=1.29.5
export TARGET_REVISION=1-29-5
```

Verify Kubernetes compatibility before upgrading.

## Install a new revision

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${TARGET_ISTIO_VERSION}" TARGET_ARCH=x86_64 sh -
export PATH="$PWD/istio-${TARGET_ISTIO_VERSION}/bin:$PATH"
istioctl x precheck
istioctl install -f istio/installation/profiles/lab-profile.yaml --set revision="${TARGET_REVISION}" -y
```

## Migrate workloads

```bash
kubectl label namespace bookinfo istio.io/rev="${TARGET_REVISION}" --overwrite
kubectl label namespace default istio.io/rev="${TARGET_REVISION}" --overwrite
kubectl rollout restart deployment -n bookinfo
kubectl rollout status deployment -n bookinfo --timeout=300s
```

Verify sidecars:

```bash
kubectl get pods -n bookinfo -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].image}{"\n"}{end}'
curl -I http://172.22.0.240/productpage
```

## Remove old revision

```bash
istioctl uninstall --revision 1-24-2 -y
```

Do not use `istioctl uninstall --purge` while another revision remains installed.

## Stale webhook cleanup

If non-revisioned webhooks point to a removed `istiod` service:

```bash
kubectl delete validatingwebhookconfiguration istio-validator-istio-system --ignore-not-found
kubectl delete validatingwebhookconfiguration istiod-default-validator --ignore-not-found
kubectl delete mutatingwebhookconfiguration istio-revision-tag-default --ignore-not-found
kubectl delete mutatingwebhookconfiguration istio-sidecar-injector --ignore-not-found
```

Keep revisioned target webhooks such as `istio-validator-1-29-5-istio-system`.
