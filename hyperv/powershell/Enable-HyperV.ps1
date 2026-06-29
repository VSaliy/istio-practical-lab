[CmdletBinding(SupportsShouldProcess=$true)]
param()

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Run this script in an elevated PowerShell session."
}

$feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($feature.State -eq 'Enabled') {
    Write-Host "Hyper-V is already enabled."
    exit 0
}

if ($PSCmdlet.ShouldProcess('Microsoft-Hyper-V-All', 'Enable Windows feature')) {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Write-Host "Hyper-V enablement requested. Reboot may be required."
}
