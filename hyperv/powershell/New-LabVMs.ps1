[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$config = Import-PowerShellDataFile -Path $ConfigPath
$installerIsoPath = $config.IsoPath
$usingAutoinstallIso = $false
if ($config.ContainsKey('AutoinstallIsoPath') -and (Test-Path -LiteralPath $config.AutoinstallIsoPath)) {
    $installerIsoPath = $config.AutoinstallIsoPath
    $usingAutoinstallIso = $true
    Write-Host "Using autoinstall-enabled Ubuntu ISO: $installerIsoPath"
}

if (-not (Test-Path -LiteralPath $config.VmPath)) {
    New-Item -ItemType Directory -Path $config.VmPath -Force | Out-Null
}

$internetSwitchName = $null
if ($config.ContainsKey('InternetSwitchName') -and -not [string]::IsNullOrWhiteSpace($config.InternetSwitchName)) {
    $internetSwitch = Get-VMSwitch -Name $config.InternetSwitchName -ErrorAction SilentlyContinue
    if ($internetSwitch) {
        $internetSwitchName = $config.InternetSwitchName
        Write-Host "Using secondary internet switch for DHCP: $internetSwitchName"
    } else {
        Write-Warning "Configured InternetSwitchName was not found; VMs will use only $($config.SwitchName): $($config.InternetSwitchName)"
    }
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

        if ($node.ContainsKey('LabMacAddress') -and -not [string]::IsNullOrWhiteSpace($node.LabMacAddress)) {
            Set-VMNetworkAdapter -VMName $vmName -Name 'Network Adapter' -StaticMacAddress $node.LabMacAddress
        }

        Set-VM -Name $vmName -ProcessorCount $node.ProcessorCount -AutomaticStartAction StartIfRunning -AutomaticStopAction ShutDown -CheckpointType Production
        Set-VMFirmware -VMName $vmName -EnableSecureBoot On -SecureBootTemplate $config.SecureBootTemplate

        Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false

        if ($internetSwitchName) {
            Add-VMNetworkAdapter -VMName $vmName -Name 'Internet' -SwitchName $internetSwitchName | Out-Null
            if ($node.ContainsKey('InternetMacAddress') -and -not [string]::IsNullOrWhiteSpace($node.InternetMacAddress)) {
                Set-VMNetworkAdapter -VMName $vmName -Name 'Internet' -StaticMacAddress $node.InternetMacAddress
            }
        }

        Add-VMDvdDrive -VMName $vmName -Path $installerIsoPath | Out-Null
        Write-Host "Created VM '$vmName' with ISO attached."
    }
}

if ($usingAutoinstallIso) {
    Write-Host 'VM creation finished. Attach per-node cidata seed ISOs before first boot to run autoinstall.'
} else {
    Write-Host 'VM creation finished. Ubuntu installation is manual unless cloud-init automation is explicitly configured.'
}
