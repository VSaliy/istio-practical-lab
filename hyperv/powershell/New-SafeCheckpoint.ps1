[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1',
    [Parameter(Mandatory = $true)]
    [string]$CheckpointName
)

$config = Import-PowerShellDataFile -Path $ConfigPath
foreach ($name in $config.Nodes.Name) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm -and $vm.State -ne 'Off') {
        throw "VM '$name' must be stopped before coordinated checkpoint creation."
    }
}

foreach ($name in $config.Nodes.Name) {
    if ($PSCmdlet.ShouldProcess($name, "Create checkpoint '$CheckpointName'")) {
        Checkpoint-VM -Name $name -SnapshotName $CheckpointName | Out-Null
    }
}
