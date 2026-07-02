# cloud-init autoinstall

This directory supports unattended Ubuntu Server installation for the Hyper-V
lab. The committed files describe the workflow; local secrets and generated
node config stay out of git.

## Local input

Create a local `.env` from the committed example:

```powershell
Copy-Item .env.example .env
```

Edit `.env` and set:

- `LAB_AUTOINSTALL_USERNAME`: local Ubuntu user to create, for example `vgs`.
- `LAB_AUTOINSTALL_FULL_NAME`: display name for that user.
- `LAB_AUTOINSTALL_PASSWORD_HASH`: SHA-512 password hash for Ubuntu autoinstall.
- `LAB_AUTOINSTALL_SSH_AUTHORIZED_KEYS`: one or more public SSH keys, comma separated.

Generate the password hash from Git Bash, WSL, or any shell with OpenSSL:

```bash
openssl passwd -6
```

Do not commit `.env`, password hashes, private keys, kubeconfigs, or generated
local node config.

## Generate node config

The generator reads `.env` plus `hyperv/config/lab-config.psd1` and writes the
JSON shape consumed by `New-LabAutoinstallMedia.ps1`.

```powershell
pwsh -File hyperv/powershell/New-LabAutoinstallConfig.ps1 `
  -EnvPath .env `
  -ConfigPath hyperv/config/lab-config.psd1 `
  -OutputPath hyperv/config/autoinstall-nodes.local.json
```

The generated node config uses:

- node names and static IPs from `hyperv/config/lab-config.psd1`
- gateway from `HostInterfaceIp`
- prefix from `HostInterfacePrefix`
- nameservers `1.1.1.1` and `8.8.8.8`

Generated seed media also configures `eth1` as optional DHCP. When
`InternetSwitchName` exists in `hyperv/config/lab-config.psd1`, `New-LabVMs.ps1`
adds a second VM network adapter on that switch for internet access during
autonomous package installation.

## Generate seed ISO media

Create one `cidata` ISO per node:

```powershell
pwsh -File hyperv/powershell/New-LabAutoinstallMedia.ps1 `
  -NodesJsonPath hyperv/config/autoinstall-nodes.local.json `
  -OutputDirectory C:\HyperV\IstioLab\autoinstall
```

If you reset the lab with `Remove-Lab.ps1 -DeleteVhdx`, regenerate these seed
ISOs afterwards. That reset removes `C:\HyperV\IstioLab`, including
`C:\HyperV\IstioLab\autoinstall`.

The ISO creation script searches for `oscdimg.exe`, `mkisofs`, `genisoimage`,
or `xorriso`. On Windows, it also checks the Windows ADK amd64 `oscdimg.exe`
path when `oscdimg.exe` is installed but not on `PATH`.

## Generate an autoinstall-enabled installer ISO

Ubuntu Server can read the attached `cidata` seed ISO but still pause for a
confirmation unless the installer was booted with the `autoinstall` kernel
argument. Build a local copy of the Ubuntu installer ISO with that GRUB argument
preconfigured:

```powershell
pwsh -File hyperv/powershell/New-LabAutoinstallInstallerIso.ps1 `
  -ConfigPath hyperv/config/lab-config.psd1 `
  -Force
```

The generated ISO is written to `AutoinstallIsoPath` from
`hyperv/config/lab-config.psd1`. `New-LabVMs.ps1` uses that ISO automatically
when it exists; otherwise it falls back to `IsoPath`.

After VM creation, attach the generated seed ISO files:

```powershell
pwsh -File hyperv/powershell/Add-LabAutoinstallMedia.ps1 `
  -NodesJsonPath hyperv/config/autoinstall-nodes.local.json `
  -MediaDirectory C:\HyperV\IstioLab\autoinstall
```

## Fully autonomous lab flow

The one-shot wrapper resets the Hyper-V lab, starts Ubuntu autoinstall, waits
for SSH, then runs cluster bootstrap from `k8s-control-01`:

```powershell
pwsh -File hyperv/powershell/Invoke-LabAutonomousBootstrap.ps1 `
  -ConfigPath hyperv/config/lab-config.psd1 `
  -NodesJsonPath hyperv/config/autoinstall-nodes.local.json `
  -MediaDirectory C:\ISO `
  -RepoBranch feature/excercises
```

This script is destructive: it calls `Remove-Lab.ps1 -DeleteVhdx`. Run it from
an Administrator PowerShell session.

For noninteractive Ansible and `kubeadm`, generated autoinstall seed media adds
a lab-only sudoers file for the configured user:

```text
/etc/sudoers.d/90-lab-automation
```

The Windows SSH client must have an agent-loaded private key matching
`LAB_AUTOINSTALL_SSH_AUTHORIZED_KEYS`. The wrapper uses SSH agent forwarding so
`k8s-control-01` can run Ansible and worker join commands against the worker
nodes without storing private keys on the VMs.
