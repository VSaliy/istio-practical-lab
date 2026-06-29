[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$failures = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Config file not found: $ConfigPath" }
$config = Import-PowerShellDataFile -Path $ConfigPath

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
    Write-Error $Message
}

$edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
if ($edition -notin @('Professional', 'Enterprise', 'Education')) {
    Add-Failure "Windows edition '$edition' does not support Hyper-V lab requirements."
}

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Add-Failure 'Administrator privileges are required.'
}

$hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($hyperv.State -ne 'Enabled') {
    Add-Failure 'Hyper-V feature is not enabled.'
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Add-Failure 'PowerShell 7 or newer is required.'
}

$memoryGB = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
if ($memoryGB -lt 16) {
    Add-Failure "Insufficient RAM: ${memoryGB}GB (minimum 16GB)."
}

$vmDrive = Split-Path -Path $config.VmPath -Qualifier
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$vmDrive'"
if (-not $disk -or $disk.FreeSpace -lt 100GB) {
    Add-Failure "Insufficient disk space on $vmDrive. Minimum 100GB free required."
}

$requiredCommands = @('Get-VM', 'Get-VMSwitch', 'New-NetNat', 'Get-NetRoute')
foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Add-Failure "Required command missing: $cmd"
    }
}

foreach ($node in $config.Nodes) {
    if (Get-VM -Name $node.Name -ErrorAction SilentlyContinue) {
        Add-Failure "Conflicting VM already exists: $($node.Name)"
    }
}

if (Get-NetNat -Name $config.NatName -ErrorAction SilentlyContinue) {
    Write-Warning "NAT '$($config.NatName)' already exists; script expects idempotent reuse if prefix matches."
}

$prefixParts = $config.NatPrefix -split '/'
$prefixBase = $prefixParts[0]
$routeConflicts = Get-NetRoute -AddressFamily IPv4 | Where-Object {
    $_.DestinationPrefix -eq $config.NatPrefix -and $_.InterfaceAlias -notlike "vEthernet ($($config.SwitchName))*"
}
if ($routeConflicts) {
    Add-Failure "Route conflict detected for $($config.NatPrefix)."
}

if (-not (Test-Path -LiteralPath $config.IsoPath)) {
    Add-Failure "Ubuntu ISO not found at $($config.IsoPath)"
}

if ($failures.Count -gt 0) {
    Write-Host "Prerequisite checks failed: $($failures.Count)"
    exit 1
}

Write-Host 'All mandatory prerequisite checks passed.'
exit 0
