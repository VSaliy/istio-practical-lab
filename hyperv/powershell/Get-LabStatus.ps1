[CmdletBinding()]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1'
)

$config = Import-PowerShellDataFile -Path $ConfigPath
Get-VM -Name $config.Nodes.Name -ErrorAction SilentlyContinue |
    Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime |
    Format-Table -AutoSize

Get-NetNat -Name $config.NatName -ErrorAction SilentlyContinue | Format-List Name, InternalIPInterfaceAddressPrefix
