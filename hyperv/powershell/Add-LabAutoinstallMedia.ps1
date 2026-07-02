[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$NodesJsonPath,

    [Parameter(Mandatory)]
    [string]$MediaDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedNodesJsonPath = Resolve-Path -LiteralPath $NodesJsonPath
if (-not (Test-Path -LiteralPath $MediaDirectory)) {
    throw "Autoinstall media directory not found: $MediaDirectory. If you ran Remove-Lab.ps1 -DeleteVhdx, regenerate seed media with New-LabAutoinstallMedia.ps1 before attaching it."
}
$resolvedMediaDirectory = Resolve-Path -LiteralPath $MediaDirectory
$config = Get-Content -LiteralPath $resolvedNodesJsonPath -Raw | ConvertFrom-Json

foreach ($node in $config.nodes) {
    $vmName = [string]$node.name
    $isoPath = Join-Path $resolvedMediaDirectory "$vmName\$vmName-cidata.iso"

    if (-not (Test-Path -LiteralPath $isoPath)) {
        throw "Autoinstall seed ISO not found for VM '$vmName': $isoPath"
    }

    $vm = Get-VM -Name $vmName -ErrorAction Stop
    if ($vm.State -ne 'Off') {
        Write-Host "Stopping VM '$vmName' before attaching autoinstall media."
        Stop-VM -Name $vmName -Force -TurnOff
    }

    $existingDrive = Get-VMDvdDrive -VMName $vmName | Where-Object { $_.Path -eq $isoPath } | Select-Object -First 1
    if ($existingDrive) {
        Write-Host "Autoinstall seed ISO already attached to '$vmName'."
        continue
    }

    Add-VMDvdDrive -VMName $vmName -Path $isoPath
    Write-Host "Attached autoinstall seed ISO to '$vmName': $isoPath"
}
