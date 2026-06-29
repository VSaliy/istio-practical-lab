# Exercise 01: Hyper-V Infrastructure

## Difficulty
Intermediate

## Estimated effort
120-180 minutes

## Learning objectives
- Build isolated Hyper-V NAT network for Kubernetes VMs
- Create and lifecycle-manage Ubuntu VMs safely
- Configure static Linux networking manually

## Architectural context
Windows host runs Hyper-V with internal switch + WinNAT to provide outbound connectivity without exposing lab nodes directly to LAN.

## Prerequisites
- Windows 11 Pro, administrator shell
- Ubuntu Server ISO path set in `hyperv/config/lab-config.psd1`

## Files used
- `hyperv/config/lab-config.psd1`
- `hyperv/powershell/Test-LabPrerequisites.ps1`
- `hyperv/powershell/New-LabNetwork.ps1`
- `hyperv/powershell/New-LabVMs.ps1`

## Environment checks
```powershell
pwsh -File hyperv/powershell/Test-LabPrerequisites.ps1 -ConfigPath hyperv/config/lab-config.psd1
```

## Implementation steps
1. Create switch and NAT.
2. Create VMs.
3. Install Ubuntu manually from ISO console.
4. Configure static networking in each VM.

## Commands
```powershell
pwsh -File hyperv/powershell/New-LabNetwork.ps1 -ConfigPath hyperv/config/lab-config.psd1
pwsh -File hyperv/powershell/New-LabVMs.ps1 -ConfigPath hyperv/config/lab-config.psd1
pwsh -File hyperv/powershell/Start-Lab.ps1 -ConfigPath hyperv/config/lab-config.psd1
```

```bash
# inside each Ubuntu VM (example for control-plane)
sudo tee /etc/netplan/01-istio-lab.yaml >/dev/null <<'NET'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [172.22.0.10/24]
      routes:
        - to: default
          via: 172.22.0.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
NET
sudo netplan apply
```

## Expected output
- `Get-VMSwitch IstioLabSwitch` exists
- `Get-NetNat IstioLabNat` uses `172.22.0.0/24`
- three VMs in `Running` state after startup

## Verification
```powershell
pwsh -File hyperv/powershell/Get-LabStatus.ps1 -ConfigPath hyperv/config/lab-config.psd1
```

## Failure experiments
- Run `New-LabNetwork.ps1` twice and confirm idempotent reuse.
- Trigger route conflict and verify script exits with an error.

## Troubleshooting
Check host route table and VM NIC settings before recreating resources.

## Cleanup
```powershell
pwsh -File hyperv/powershell/Stop-Lab.ps1 -ConfigPath hyperv/config/lab-config.psd1
pwsh -File hyperv/powershell/Remove-Lab.ps1 -ConfigPath hyperv/config/lab-config.psd1 -ConfirmDestruction
```

## Architectural lessons
Internal+NAT topology favors repeatability and isolation over direct LAN accessibility.

## Production considerations
Production environments usually use routed VLANs and managed IPAM instead of host-local NAT.

## Self-assessment questions
1. Why avoid overlapping NAT prefix with existing routes?
2. When should production checkpoints be created?
