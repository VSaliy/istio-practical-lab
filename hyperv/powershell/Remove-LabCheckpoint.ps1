[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1',
    [Parameter(Mandatory = $true)]
    [string]$CheckpointName
)

$config = Import-PowerShellDataFile -Path $ConfigPath
foreach ($name in $config.Nodes.Name) {
    $snap = Get-VMSnapshot -VMName $name -Name $CheckpointName -ErrorAction SilentlyContinue
    if ($snap -and $PSCmdlet.ShouldProcess($name, "Remove checkpoint '$CheckpointName'")) {
        Remove-VMSnapshot -VMName $name -Name $CheckpointName
    }
}
