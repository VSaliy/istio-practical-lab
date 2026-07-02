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

    $adkOscdimgPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
    $oscdimg = $null
    if (Test-Path -LiteralPath $adkOscdimgPath) {
        $oscdimg = Get-Item -LiteralPath $adkOscdimgPath
    }
    if (-not $oscdimg) {
        $oscdimg = Get-Command oscdimg.exe -ErrorAction SilentlyContinue
    }

    if ($oscdimg) {
        $oscdimgPath = if ($oscdimg.PSObject.Properties.Name -contains 'Source') { $oscdimg.Source } else { $oscdimg.FullName }
        & $oscdimgPath -o -m -j2 -lCIDATA $SourceDirectory $IsoPath | Out-Host
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
    $autoinstallNameserverYaml = ($node.nameservers | ForEach-Object { "            - $_" }) -join [Environment]::NewLine
    $labMacAddress = if ($node.PSObject.Properties.Name -contains 'lab_mac_address') { [string]$node.lab_mac_address } else { '' }
    $internetMacAddress = if ($node.PSObject.Properties.Name -contains 'internet_mac_address') { [string]$node.internet_mac_address } else { '' }

    if ([string]::IsNullOrWhiteSpace($labMacAddress)) {
        throw "Node $($node.name) is missing lab_mac_address. Regenerate $NodesJsonPath with New-LabAutoinstallConfig.ps1."
    }

    if ([string]::IsNullOrWhiteSpace($internetMacAddress)) {
        throw "Node $($node.name) is missing internet_mac_address. Regenerate $NodesJsonPath with New-LabAutoinstallConfig.ps1."
    }

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
  network:
    version: 2
    ethernets:
      lab:
        match:
          macaddress: "$labMacAddress"
        set-name: eth0
        dhcp4: false
        addresses:
          - $($node.address)/$($node.prefix)
        routes:
          - to: default
            via: $($node.gateway)
        nameservers:
          addresses:
$autoinstallNameserverYaml
      internet:
        match:
          macaddress: "$internetMacAddress"
        set-name: eth1
        dhcp4: true
        optional: true
  updates: security
  late-commands:
    - curtin in-target --target=/target -- systemctl enable ssh
    - curtin in-target --target=/target -- sh -c 'echo "$($config.username) ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-lab-automation'
    - curtin in-target --target=/target -- chmod 0440 /etc/sudoers.d/90-lab-automation
"@

    $metaData = @"
instance-id: $($node.name)
local-hostname: $($node.hostname)
"@

    $networkConfig = @"
version: 2
ethernets:
  lab:
    match:
      macaddress: "$labMacAddress"
    set-name: eth0
    dhcp4: false
    addresses:
      - $($node.address)/$($node.prefix)
    routes:
      - to: default
        via: $($node.gateway)
    nameservers:
      addresses:
$nameserverYaml
  internet:
    match:
      macaddress: "$internetMacAddress"
    set-name: eth1
    dhcp4: true
    optional: true
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
