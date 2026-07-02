[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ConfigPath,

    [string]$WorkDirectory,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-OscdimgPath {
    $adkOscdimgPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
    if (Test-Path -LiteralPath $adkOscdimgPath) {
        return $adkOscdimgPath
    }

    $oscdimg = Get-Command oscdimg.exe -ErrorAction SilentlyContinue
    if ($oscdimg) {
        return $oscdimg.Source
    }

    throw "oscdimg.exe was not found. Install Windows ADK or add oscdimg.exe to PATH."
}

function Update-GrubAutoinstall {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $content = Get-Content -LiteralPath $Path -Raw
    $content = $content -replace 'linux(\s+)/casper/vmlinuz\s+---', 'linux$1/casper/vmlinuz autoinstall ---'
    $content = $content -replace 'linux(\s+)/casper/hwe-vmlinuz\s+---', 'linux$1/casper/hwe-vmlinuz autoinstall ---'
    $content = $content -replace 'linux(\s+)/casper/vmlinuz\s+iso-scan/filename=\$\{iso_path\}\s+---', 'linux$1/casper/vmlinuz autoinstall iso-scan/filename=${iso_path} ---'
    $content = $content -replace 'linux(\s+)/casper/hwe-vmlinuz\s+iso-scan/filename=\$\{iso_path\}\s+---', 'linux$1/casper/hwe-vmlinuz autoinstall iso-scan/filename=${iso_path} ---'
    Set-Content -LiteralPath $Path -Value $content -Encoding utf8NoBOM
}

$config = Import-PowerShellDataFile -LiteralPath $ConfigPath
if (-not $config.ContainsKey('AutoinstallIsoPath') -or [string]::IsNullOrWhiteSpace($config.AutoinstallIsoPath)) {
    throw "Config must define AutoinstallIsoPath."
}

$sourceIso = Resolve-Path -LiteralPath $config.IsoPath
$outputIso = $config.AutoinstallIsoPath
$outputParent = Split-Path -Parent $outputIso
if (-not [string]::IsNullOrWhiteSpace($outputParent)) {
    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
}

if ((Test-Path -LiteralPath $outputIso) -and -not $Force) {
    Write-Host "Autoinstall-enabled installer ISO already exists: $outputIso"
    return
}

if ([string]::IsNullOrWhiteSpace($WorkDirectory)) {
    $WorkDirectory = Join-Path $env:TEMP 'istio-lab-autoinstall-iso'
}

$extractDirectory = Join-Path $WorkDirectory 'extract'
Remove-Item -LiteralPath $extractDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $extractDirectory -Force | Out-Null

$sevenZip = Get-Command 7z.exe -ErrorAction SilentlyContinue
if (-not $sevenZip) {
    $sevenZip = Get-Command 7z -ErrorAction SilentlyContinue
}
if (-not $sevenZip) {
    throw "7z.exe was not found. Install 7-Zip or add it to PATH."
}

Write-Host "Extracting Ubuntu installer ISO to: $extractDirectory"
& $sevenZip.Source x $sourceIso "-o$extractDirectory" -y | Out-Host
if ($LASTEXITCODE -ne 0) {
    throw "7-Zip extraction failed with exit code $LASTEXITCODE"
}

$grubCfg = Join-Path $extractDirectory 'boot\grub\grub.cfg'
$loopbackCfg = Join-Path $extractDirectory 'boot\grub\loopback.cfg'
foreach ($file in @($grubCfg, $loopbackCfg)) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Expected GRUB config not found: $file"
    }
    Update-GrubAutoinstall -Path $file
}

$biosBootImage = Join-Path $extractDirectory '[BOOT]\1-Boot-NoEmul.img'
$uefiBootImage = Join-Path $extractDirectory '[BOOT]\2-Boot-NoEmul.img'
if (-not (Test-Path -LiteralPath $biosBootImage)) {
    throw "BIOS boot image not found after extraction: $biosBootImage"
}
if (-not (Test-Path -LiteralPath $uefiBootImage)) {
    throw "UEFI boot image not found after extraction: $uefiBootImage"
}

if (Test-Path -LiteralPath $outputIso) {
    Remove-Item -LiteralPath $outputIso -Force
}

$oscdimgPath = Get-OscdimgPath
Write-Host "Creating autoinstall-enabled Ubuntu installer ISO: $outputIso"
& $oscdimgPath `
    -m `
    -o `
    -j2 `
    "-bootdata:2#p0,e,b$biosBootImage#pEF,e,b$uefiBootImage" `
    -lUBUNTU_AUTO `
    $extractDirectory `
    $outputIso | Out-Host

if ($LASTEXITCODE -ne 0) {
    throw "oscdimg.exe failed with exit code $LASTEXITCODE"
}

Write-Host "Created autoinstall-enabled installer ISO: $outputIso"
