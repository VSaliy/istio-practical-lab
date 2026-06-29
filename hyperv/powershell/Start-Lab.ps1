[CmdletBinding()]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1'
)

$config = Import-PowerShellDataFile -Path $ConfigPath
$config.Nodes.Name | ForEach-Object {
    if (Get-VM -Name $_ -ErrorAction SilentlyContinue) {
        Start-VM -Name $_ | Out-Null
        Write-Host "Started $_"
    }
}
