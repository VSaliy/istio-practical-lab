# Storage

This lab does not install a dynamic storage provisioner by default.

## Current Boundary

- VM disks are created and managed by Hyper-V.
- Kubernetes system components use node-local storage where required.
- Bookinfo is stateless.
- No production-grade `StorageClass` is included.

## Checks

```bash
kubectl get storageclass
kubectl get pv,pvc -A
```

Expected baseline:

- no default production storage class is required
- no persistent volumes are required for Bookinfo

## Production Comparison

Production clusters should use a supported CSI driver, tested backup and restore, encryption requirements, volume expansion policy, and workload-specific recovery objectives.

## Lab Guidance

Do not add persistence to Bookinfo unless a later exercise explicitly needs it. Keeping application state out of this layer makes traffic, policy, and observability exercises easier to reset.
