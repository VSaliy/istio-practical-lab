[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$config = Import-PowerShellDataFile -Path $ConfigPath

if (-not (Test-Path -LiteralPath $config.VmPath)) {
    New-Item -ItemType Directory -Path $config.VmPath -Force | Out-Null
}

foreach ($node in $config.Nodes) {
    $vmName = $node.Name
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    $vmDir = Join-Path $config.VmPath $vmName
    $vhdPath = Join-Path $vmDir "$vmName.vhdx"

    if ($vm) {
        Write-Host "VM '$vmName' already exists; skipping creation."
        continue
    }

    if (-not (Test-Path -LiteralPath $vmDir)) {
        New-Item -ItemType Directory -Path $vmDir -Force | Out-Null
    }

    if ($PSCmdlet.ShouldProcess($vmName, 'Create Generation 2 VM')) {
        $memoryBytes = [Int64]$node.StartupMemoryGB * 1GB
        $vhdBytes = [UInt64]$node.VhdSizeGB * 1GB
        New-VM -Name $vmName -Generation 2 -MemoryStartupBytes $memoryBytes -SwitchName $config.SwitchName -Path $vmDir -NewVHDPath $vhdPath -NewVHDSizeBytes $vhdBytes | Out-Null

        Set-VM -Name $vmName -ProcessorCount $node.ProcessorCount -AutomaticStartAction StartIfRunning -AutomaticStopAction ShutDown -CheckpointType Production
        Set-VMFirmware -VMName $vmName -EnableSecureBoot On -SecureBootTemplate $config.SecureBootTemplate

        Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false

        Add-VMDvdDrive -VMName $vmName -Path $config.IsoPath | Out-Null
        Write-Host "Created VM '$vmName' with ISO attached."
    }
}

Write-Host 'VM creation finished. Ubuntu installation is manual unless cloud-init automation is explicitly configured.'
