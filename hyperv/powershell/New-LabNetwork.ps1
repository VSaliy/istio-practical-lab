[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$config = Import-PowerShellDataFile -Path $ConfigPath

$routeConflict = Get-NetRoute -AddressFamily IPv4 | Where-Object {
    $_.DestinationPrefix -eq $config.NatPrefix -and $_.InterfaceAlias -notlike "vEthernet ($($config.SwitchName))*"
}
if ($routeConflict) {
    throw "Route conflict exists for $($config.NatPrefix). Resolve before continuing."
}

$switch = Get-VMSwitch -Name $config.SwitchName -ErrorAction SilentlyContinue
if (-not $switch) {
    if ($PSCmdlet.ShouldProcess($config.SwitchName, 'Create internal Hyper-V switch')) {
        New-VMSwitch -Name $config.SwitchName -SwitchType Internal | Out-Null
        Write-Host "Created switch $($config.SwitchName)."
    }
} else {
    Write-Host "Switch $($config.SwitchName) already exists; reusing."
}

$ifAlias = "vEthernet ($($config.SwitchName))"
$existingIp = Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $config.HostInterfaceIp }
if (-not $existingIp) {
    if ($PSCmdlet.ShouldProcess($ifAlias, "Assign $($config.HostInterfaceIp)/$($config.HostInterfacePrefix)")) {
        New-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $config.HostInterfaceIp -PrefixLength $config.HostInterfacePrefix | Out-Null
        Write-Host "Assigned host vNIC IP."
    }
} else {
    Write-Host "Host vNIC already has expected IP $($config.HostInterfaceIp)."
}

$nat = Get-NetNat -Name $config.NatName -ErrorAction SilentlyContinue
if (-not $nat) {
    $prefixInUse = Get-NetNat | Where-Object { $_.InternalIPInterfaceAddressPrefix -eq $config.NatPrefix }
    if ($prefixInUse) {
        throw "NAT prefix $($config.NatPrefix) is already used by $($prefixInUse.Name)."
    }
    if ($PSCmdlet.ShouldProcess($config.NatName, "Create WinNAT with $($config.NatPrefix)")) {
        New-NetNat -Name $config.NatName -InternalIPInterfaceAddressPrefix $config.NatPrefix | Out-Null
        Write-Host "Created NAT $($config.NatName)."
    }
} elseif ($nat.InternalIPInterfaceAddressPrefix -ne $config.NatPrefix) {
    throw "Existing NAT '$($config.NatName)' has different prefix: $($nat.InternalIPInterfaceAddressPrefix)"
} else {
    Write-Host "NAT $($config.NatName) already configured; reusing."
}

Write-Host "Verification commands:"
Write-Host "  Get-VMSwitch -Name '$($config.SwitchName)'"
Write-Host "  Get-NetIPAddress -InterfaceAlias 'vEthernet ($($config.SwitchName))' -AddressFamily IPv4"
Write-Host "  Get-NetNat -Name '$($config.NatName)'"
