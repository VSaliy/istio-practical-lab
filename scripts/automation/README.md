# Automation scripts

`bootstrap-autonomous-lab.sh` runs on `k8s-control-01` after Ubuntu autoinstall
finishes. It is normally invoked by:

```powershell
pwsh -File hyperv/powershell/Invoke-LabAutonomousBootstrap.ps1 `
  -ConfigPath hyperv/config/lab-config.psd1 `
  -NodesJsonPath hyperv/config/autoinstall-nodes.local.json `
  -MediaDirectory C:\ISO `
  -RepoBranch feature/excercises
```

The Linux script performs:

1. install bootstrap prerequisites on the control node
2. clone `https://github.com/VSaliy/istio-practical-lab.git`
3. check out `feature/excercises`
4. prepare all nodes with Ansible
5. initialize Kubernetes
6. join workers
7. install Calico, Metrics Server, MetalLB
8. install Istio and Bookinfo
9. install Argo CD and apply the Bookinfo GitOps application
10. run final validation

The flow assumes SSH agent forwarding from Windows and passwordless sudo from
the generated lab autoinstall seed media.
