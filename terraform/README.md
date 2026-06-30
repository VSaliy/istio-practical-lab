# Terraform Hyper-V Wrapper

This Terraform layer orchestrates the existing Hyper-V PowerShell automation and generates per-VM Ubuntu autoinstall seed ISOs.

It is intentionally a wrapper around the working scripts in `hyperv/powershell/` rather than a replacement for them.

## What Terraform Does

1. Writes `build/autoinstall/nodes.json` from Terraform variables.
2. Generates NoCloud seed content for each VM:
   - `user-data`
   - `meta-data`
   - `network-config`
3. Builds a per-VM `cidata` ISO when an ISO creation tool is available.
4. Runs the existing lab scripts:
   - `New-LabNetwork.ps1`
   - `New-LabVMs.ps1`
   - `Add-LabAutoinstallMedia.ps1`
   - `Start-Lab.ps1`

## Important Autoinstall Note

The generated seed ISO contains valid cloud-init/autoinstall data, but Ubuntu Server autoinstall also needs the installer boot command line to include:

```text
autoinstall ds=nocloud
```

For fully unattended boot, use a remastered Ubuntu ISO with that boot argument embedded. Without a remastered ISO, attach the generated seed ISO and manually add the boot argument once in the Ubuntu installer boot menu.

## Prerequisites

- Administrator PowerShell session
- Terraform installed
- PowerShell 7 available as `pwsh`
- Hyper-V enabled
- One ISO creation tool available:
  - `oscdimg.exe` from Windows ADK
  - `mkisofs`
  - `genisoimage`
  - `xorriso`

Check:

```powershell
pwsh -NoProfile -Command "Get-Command oscdimg,mkisofs,genisoimage,xorriso -ErrorAction SilentlyContinue"
```

## Configure

Copy the sample variables file:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:

- `admin_password_hash`
- optionally `ssh_authorized_keys`

Generate a SHA-512 password hash from an Ubuntu machine:

```bash
openssl passwd -6
```

## Run

From this directory:

```powershell
terraform init
terraform apply
```

## Destroy/Cleanup

Terraform does not destroy Hyper-V resources directly. Use the existing explicit destructive lab script:

```powershell
pwsh -File ../hyperv/powershell/Remove-Lab.ps1 -ConfigPath ../hyperv/config/lab-config.psd1 -ConfirmDestruction
```

Then clean generated local artifacts if desired:

```powershell
Remove-Item -Recurse -Force ../build/autoinstall
```

## Files Generated

```text
build/autoinstall/
  nodes.json
  k8s-control-01/
    user-data
    meta-data
    network-config
    k8s-control-01-cidata.iso
  k8s-worker-01/
    ...
  k8s-worker-02/
    ...
```

