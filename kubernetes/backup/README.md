# Backup and Restore

This lab uses Hyper-V checkpoints for coarse VM recovery and Kubernetes diagnostics for state inspection. It does not implement a production backup system.

## Safe Lab Checkpoints

Before destructive experiments, create Hyper-V checkpoints from Windows:

```powershell
pwsh -File hyperv/powershell/New-SafeCheckpoint.ps1 -ConfigPath hyperv/config/lab-config.psd1 -CheckpointName BeforeExperiment
```

Remove old checkpoints when no longer needed:

```powershell
pwsh -File hyperv/powershell/Remove-LabCheckpoint.ps1 -ConfigPath hyperv/config/lab-config.psd1 -CheckpointName BeforeExperiment
```

## Kubernetes Diagnostics

Before changing cluster state:

```bash
bash scripts/diagnostics/collect-cluster-diagnostics.sh
```

## etcd Snapshot Note

This single-control-plane lab can be snapshotted at the VM level. For production or a dedicated etcd exercise, use explicit etcd snapshot and restore procedures with tested certificates and restore drills.

Typical production-grade etcd snapshot command shape:

```bash
sudo ETCDCTL_API=3 etcdctl snapshot save /var/backups/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Do not treat a snapshot as valid until restore has been tested.
