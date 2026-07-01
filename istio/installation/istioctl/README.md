# Istioctl Installation Path

Install Istio with `istioctl` and the lab `IstioOperator` profile.

## Install pinned version

```bash
set -a
. ./versions.env
set +a
curl -L https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" TARGET_ARCH=x86_64 sh -
export PATH="$PWD/istio-${ISTIO_VERSION}/bin:$PATH"
istioctl version --remote=false
```

## Precheck and install

```bash
istioctl x precheck
istioctl install -f istio/installation/profiles/lab-profile.yaml -y
```

## Label namespaces

```bash
kubectl label namespace default istio.io/rev="${ISTIO_REVISION}" --overwrite
kubectl label namespace bookinfo istio.io/rev="${ISTIO_REVISION}" --overwrite
```

## Verify

```bash
kubectl get pods -n istio-system
kubectl get mutatingwebhookconfiguration | grep istio
kubectl get validatingwebhookconfiguration | grep istio
istioctl analyze -A
```
