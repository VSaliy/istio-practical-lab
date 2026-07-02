[CmdletBinding()]
param(
    [string]$EnvPath = '.env',

    [string]$ConfigPath = 'hyperv/config/lab-config.psd1',

    [string]$OutputPath = 'hyperv/config/autoinstall-nodes.local.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-DotEnv {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $resolvedPath = Resolve-Path -LiteralPath $Path
    $values = @{}

    foreach ($line in Get-Content -LiteralPath $resolvedPath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }

        $separatorIndex = $trimmed.IndexOf('=')
        if ($separatorIndex -lt 1) {
            throw "Invalid .env line. Expected KEY=VALUE: $line"
        }

        $key = $trimmed.Substring(0, $separatorIndex).Trim()
        $value = $trimmed.Substring($separatorIndex + 1).Trim()

        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        if ([string]::IsNullOrWhiteSpace($key)) {
            throw "Invalid .env line with empty key: $line"
        }

        $values[$key] = $value
    }

    return $values
}

function Get-RequiredEnvValue {
    param(
        [Parameter(Mandatory)][hashtable]$Values,
        [Parameter(Mandatory)][string]$Name
    )

    if (-not $Values.ContainsKey($Name) -or [string]::IsNullOrWhiteSpace([string]$Values[$Name])) {
        throw "Missing required .env value: $Name"
    }

    return [string]$Values[$Name]
}

function ConvertTo-StringArray {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    $items = @(
        $Value -split '\r?\n|,' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    return $items
}

function ConvertTo-ColonMacAddress {
    param([string]$MacAddress)

    if ([string]::IsNullOrWhiteSpace($MacAddress)) {
        return $null
    }

    $normalized = ($MacAddress -replace '[:-]', '').ToLowerInvariant()
    if ($normalized.Length -ne 12 -or $normalized -notmatch '^[0-9a-f]{12}$') {
        throw "Invalid MAC address: $MacAddress"
    }

    return (($normalized -split '(.{2})' | Where-Object { $_ }) -join ':')
}

$envValues = Read-DotEnv -Path $EnvPath
$labConfigPath = Resolve-Path -LiteralPath $ConfigPath
$labConfig = Import-PowerShellDataFile -LiteralPath $labConfigPath

$username = Get-RequiredEnvValue -Values $envValues -Name 'LAB_AUTOINSTALL_USERNAME'
$fullName = Get-RequiredEnvValue -Values $envValues -Name 'LAB_AUTOINSTALL_FULL_NAME'
$passwordHash = Get-RequiredEnvValue -Values $envValues -Name 'LAB_AUTOINSTALL_PASSWORD_HASH'
[string[]]$sshAuthorizedKeys = ConvertTo-StringArray -Value (Get-RequiredEnvValue -Values $envValues -Name 'LAB_AUTOINSTALL_SSH_AUTHORIZED_KEYS')

if ($passwordHash -eq 'replace-with-openssl-passwd-6-output') {
    throw "LAB_AUTOINSTALL_PASSWORD_HASH still contains the placeholder value. Generate one with: openssl passwd -6"
}

if ($sshAuthorizedKeys.Count -eq 0 -or $sshAuthorizedKeys[0] -like 'ssh-ed25519 AAAA...*') {
    throw "LAB_AUTOINSTALL_SSH_AUTHORIZED_KEYS still contains the placeholder value. Add at least one public SSH key."
}

if ($sshAuthorizedKeys -match 'FakeAutoinstallPublicKeyForLocalTestOnly') {
    throw "LAB_AUTOINSTALL_SSH_AUTHORIZED_KEYS contains the local fake test key. Replace it with your real public SSH key."
}

$nodes = @(
    foreach ($node in $labConfig.Nodes) {
        [ordered]@{
            name        = [string]$node.Name
            hostname    = [string]$node.Name
            address     = [string]$node.IpAddress
            prefix      = [int]$labConfig.HostInterfacePrefix
            gateway     = [string]$labConfig.HostInterfaceIp
            nameservers = @('1.1.1.1', '8.8.8.8')
            lab_mac_address = ConvertTo-ColonMacAddress -MacAddress $node.LabMacAddress
            internet_mac_address = ConvertTo-ColonMacAddress -MacAddress $node.InternetMacAddress
        }
    }
)

$autoinstallConfig = [ordered]@{
    username            = $username
    full_name           = $fullName
    password_hash       = $passwordHash
    ssh_authorized_keys = $sshAuthorizedKeys
    nodes               = $nodes
}

$outputParent = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

$autoinstallConfig |
    ConvertTo-Json -Depth 10 |
    Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM

Write-Host "Created local autoinstall node config: $OutputPath"
