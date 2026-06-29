# Bookinfo Deployment

## Commands

```bash
bash scripts/install/install-istio.sh
bash scripts/install/deploy-bookinfo.sh
```

## Verify

```bash
kubectl -n bookinfo get pods,svc
kubectl -n istio-system get svc istio-ingressgateway
```

## Access from Windows

1. Map `bookinfo.istio.local` in `C:\Windows\System32\drivers\etc\hosts` to MetalLB IP.
2. Test:

```powershell
curl.exe http://bookinfo.istio.local/productpage
Test-NetConnection -ComputerName bookinfo.istio.local -Port 80
```
