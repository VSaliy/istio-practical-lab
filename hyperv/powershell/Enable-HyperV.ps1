[CmdletBinding(SupportsShouldProcess=$true)]
param()

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Run this script in an elevated PowerShell session."
}

$vmms = Get-Service -Name vmms -ErrorAction SilentlyContinue
$hasHyperVModule = [bool](Get-Command Get-VM -ErrorAction SilentlyContinue)
if ($vmms -and $hasHyperVModule) {
    Write-Host "Hyper-V is already enabled."
    exit 0
}

if ($PSCmdlet.ShouldProcess('Microsoft-Hyper-V-All', 'Enable Windows feature')) {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Write-Host "Hyper-V enablement requested. Reboot may be required."
}
