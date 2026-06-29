[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1',
    [switch]$ConfirmDestruction,
    [switch]$DeleteVhdx
)

if (-not $ConfirmDestruction) {
    throw 'Refusing destructive operation. Re-run with -ConfirmDestruction.'
}

$config = Import-PowerShellDataFile -Path $ConfigPath

foreach ($name in $config.Nodes.Name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm) {
        if ($vm.State -eq 'Running') { Stop-VM -Name $name -Shutdown -Force }
        if ($PSCmdlet.ShouldProcess($name, 'Remove VM')) {
            Remove-VM -Name $name -Force
        }
    }
}

$nat = Get-NetNat -Name $config.NatName -ErrorAction SilentlyContinue
if ($nat -and $PSCmdlet.ShouldProcess($config.NatName, 'Remove NAT')) {
    Remove-NetNat -Name $config.NatName -Confirm:$false
}

$switch = Get-VMSwitch -Name $config.SwitchName -ErrorAction SilentlyContinue
if ($switch -and $PSCmdlet.ShouldProcess($config.SwitchName, 'Remove virtual switch')) {
    Remove-VMSwitch -Name $config.SwitchName -Force
}

if ($DeleteVhdx) {
    Write-Warning 'Deleting VHDX files from VM path was explicitly requested.'
    if ($PSCmdlet.ShouldProcess($config.VmPath, 'Remove VM directory recursively')) {
        Remove-Item -Path $config.VmPath -Recurse -Force
    }
} else {
    Write-Host 'VHDX files preserved by default.'
}
