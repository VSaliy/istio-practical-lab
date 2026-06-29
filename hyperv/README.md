# Hyper-V Automation

## Scripts

- `Test-LabPrerequisites.ps1` validates host requirements and conflicting resources.
- `New-LabNetwork.ps1` configures internal switch + host vNIC + NAT.
- `New-LabVMs.ps1` creates Generation 2 Ubuntu VMs from `hyperv/config/lab-config.psd1`.
- lifecycle scripts start/stop/status/checkpoint/remove lab assets.

## Safety

Destructive actions require `-ConfirmDestruction`.
VHDX files are preserved by default.
