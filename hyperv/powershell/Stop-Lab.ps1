[CmdletBinding()]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1'
)

$config = Import-PowerShellDataFile -Path $ConfigPath
$config.Nodes.Name | ForEach-Object {
    $vm = Get-VM -Name $_ -ErrorAction SilentlyContinue
    if ($vm -and $vm.State -eq 'Running') {
        Stop-VM -Name $_ -Shutdown -Force
        Write-Host "Stopped $_"
    }
}
