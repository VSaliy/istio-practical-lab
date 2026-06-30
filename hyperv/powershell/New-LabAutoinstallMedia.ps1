[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$NodesJsonPath,

    [Parameter(Mandatory)]
    [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-YamlList {
    param([string[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        return ''
    }

    return ($Items | ForEach-Object { "      - $_" }) -join [Environment]::NewLine
}

function New-SeedIso {
    param(
        [Parameter(Mandatory)][string]$SourceDirectory,
        [Parameter(Mandatory)][string]$IsoPath
    )

    $oscdimg = Get-Command oscdimg.exe -ErrorAction SilentlyContinue
    if ($oscdimg) {
        & $oscdimg.Source -o -m -j2 -lCIDATA $SourceDirectory $IsoPath | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "oscdimg.exe failed with exit code $LASTEXITCODE"
        }
        return
    }

    $mkisofs = Get-Command mkisofs -ErrorAction SilentlyContinue
    if ($mkisofs) {
        & $mkisofs.Source -output $IsoPath -volid cidata -joliet -rock $SourceDirectory | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "mkisofs failed with exit code $LASTEXITCODE"
        }
        return
    }

    $genisoimage = Get-Command genisoimage -ErrorAction SilentlyContinue
    if ($genisoimage) {
        & $genisoimage.Source -output $IsoPath -volid cidata -joliet -rock $SourceDirectory | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "genisoimage failed with exit code $LASTEXITCODE"
        }
        return
    }

    $xorriso = Get-Command xorriso -ErrorAction SilentlyContinue
    if ($xorriso) {
        & $xorriso.Source -as mkisofs -output $IsoPath -volid cidata -joliet -rock $SourceDirectory | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "xorriso failed with exit code $LASTEXITCODE"
        }
        return
    }

    throw "No ISO creation tool found. Install Windows ADK oscdimg.exe, mkisofs, genisoimage, or xorriso."
}

$resolvedNodesJsonPath = Resolve-Path -LiteralPath $NodesJsonPath
$config = Get-Content -LiteralPath $resolvedNodesJsonPath -Raw | ConvertFrom-Json

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

foreach ($node in $config.nodes) {
    $nodeDir = Join-Path $OutputDirectory $node.name
    $seedDir = Join-Path $nodeDir 'seed'
    New-Item -ItemType Directory -Path $nodeDir -Force | Out-Null
    New-Item -ItemType Directory -Path $seedDir -Force | Out-Null

    $sshKeysYaml = ConvertTo-YamlList -Items @($config.ssh_authorized_keys)
    $sshBlock = if ([string]::IsNullOrWhiteSpace($sshKeysYaml)) {
        '    authorized-keys: []'
    } else {
        "    authorized-keys:$([Environment]::NewLine)$sshKeysYaml"
    }
    $nameserverYaml = ($node.nameservers | ForEach-Object { "          - $_" }) -join [Environment]::NewLine

    $userData = @"
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  identity:
    hostname: $($node.hostname)
    username: $($config.username)
    realname: $($config.full_name)
    password: "$($config.password_hash)"
  ssh:
    install-server: true
    allow-pw: true
$sshBlock
  packages:
    - openssh-server
  storage:
    layout:
      name: lvm
  updates: security
  late-commands:
    - curtin in-target --target=/target -- systemctl enable ssh
"@

    $metaData = @"
instance-id: $($node.name)
local-hostname: $($node.hostname)
"@

    $networkConfig = @"
version: 2
ethernets:
  eth0:
    dhcp4: false
    addresses:
      - $($node.address)/$($node.prefix)
    routes:
      - to: default
        via: $($node.gateway)
    nameservers:
      addresses:
$nameserverYaml
"@

    Set-Content -LiteralPath (Join-Path $seedDir 'user-data') -Value $userData -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $seedDir 'meta-data') -Value $metaData -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $seedDir 'network-config') -Value $networkConfig -Encoding utf8NoBOM

    $isoPath = Join-Path $nodeDir "$($node.name)-cidata.iso"
    if (Test-Path -LiteralPath $isoPath) {
        Remove-Item -LiteralPath $isoPath -Force
    }

    New-SeedIso -SourceDirectory $seedDir -IsoPath $isoPath
    Write-Host "Created autoinstall seed ISO: $isoPath"
}
