[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$ConfigPath = 'hyperv/config/lab-config.psd1',
    [string]$NodesJsonPath = 'hyperv/config/autoinstall-nodes.local.json',
    [string]$MediaDirectory = 'C:\ISO',
    [string]$RepoUrl = 'https://github.com/VSaliy/istio-practical-lab.git',
    [string]$RepoBranch = 'feature/excercises',
    [int]$SshTimeoutMinutes = 450,
    [switch]$SkipClusterBootstrap
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host ""
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
}

function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )
    Write-Step $Name
    $global:LASTEXITCODE = 0
    & $ScriptBlock
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed with native exit code $LASTEXITCODE`: $Name"
    }
}

function Test-TcpPort {
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][int]$Port
    )
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(2000, $false)) {
            return $false
        }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Wait-Ssh {
    param(
        [Parameter(Mandatory)][string[]]$Addresses,
        [Parameter(Mandatory)][int]$TimeoutMinutes
    )
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    $remaining = [System.Collections.Generic.HashSet[string]]::new([string[]]$Addresses)

    while ($remaining.Count -gt 0) {
        foreach ($address in @($remaining)) {
            if (Test-TcpPort -HostName $address -Port 22) {
                Write-Host "SSH is reachable on $address"
                [void]$remaining.Remove($address)
            }
        }

        if ($remaining.Count -eq 0) {
            return
        }
        if ((Get-Date) -ge $deadline) {
            throw "Timed out waiting for SSH on: $($remaining -join ', ')"
        }

        $remainingMinutes = [Math]::Max(0, [Math]::Round(($deadline - (Get-Date)).TotalMinutes, 1))
        Write-Host "Waiting for SSH on: $($remaining -join ', ') ($remainingMinutes minute(s) before timeout)"
        Start-Sleep -Seconds 60
    }
}

function Invoke-SshCommand {
    param(
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][string]$Command
    )
    & ssh -A -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=10 -o ServerAliveCountMax=12 "$User@$HostName" $Command
    if ($LASTEXITCODE -ne 0) {
        throw "SSH command failed on ${User}@${HostName} with exit code $LASTEXITCODE"
    }
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repoRoot
try {
    $config = Import-PowerShellDataFile -LiteralPath $ConfigPath
    $nodeConfig = Get-Content -LiteralPath (Resolve-Path -LiteralPath $NodesJsonPath) -Raw | ConvertFrom-Json
    $sshUser = [string]$nodeConfig.username
    $nodeAddresses = @($nodeConfig.nodes | ForEach-Object { [string]$_.address })
    $controlAddress = [string]$nodeConfig.nodes[0].address
    $workerAddresses = @($nodeConfig.nodes | Select-Object -Skip 1 | ForEach-Object { [string]$_.address })

    Invoke-Step 'Remove existing lab VMs, switch, NAT, and VHDX files' {
        pwsh -File hyperv/powershell/Remove-Lab.ps1 `
            -ConfigPath $ConfigPath `
            -ConfirmDestruction `
            -DeleteVhdx `
            -Confirm:$false
    }

    Invoke-Step 'Generate autoinstall seed ISO media outside the VM directory' {
        pwsh -File hyperv/powershell/New-LabAutoinstallMedia.ps1 `
            -NodesJsonPath $NodesJsonPath `
            -OutputDirectory $MediaDirectory
    }

    Invoke-Step 'Verify generated seed ISO media' {
        Get-ChildItem $MediaDirectory -Recurse -Filter '*-cidata.iso' |
            Select-Object FullName, Length, LastWriteTime |
            Format-Table -AutoSize
    }

    Invoke-Step 'Create Hyper-V switch and NAT' {
        pwsh -File hyperv/powershell/New-LabNetwork.ps1 -ConfigPath $ConfigPath
    }

    Invoke-Step 'Create lab VMs with the autoinstall-enabled Ubuntu installer ISO' {
        pwsh -File hyperv/powershell/New-LabVMs.ps1 -ConfigPath $ConfigPath
    }

    Invoke-Step 'Attach per-node cidata seed ISOs' {
        pwsh -File hyperv/powershell/Add-LabAutoinstallMedia.ps1 `
            -NodesJsonPath $NodesJsonPath `
            -MediaDirectory $MediaDirectory
    }

    Invoke-Step 'Show attached DVD media' {
        Get-VMDvdDrive -VMName $config.Nodes.Name | Select-Object VMName, Path | Format-Table -AutoSize
    }

    Invoke-Step 'Start lab VMs' {
        pwsh -File hyperv/powershell/Start-Lab.ps1 -ConfigPath $ConfigPath
    }

    Invoke-Step 'Wait for SSH on all nodes after autoinstall' {
        Wait-Ssh -Addresses $nodeAddresses -TimeoutMinutes $SshTimeoutMinutes
    }

    Invoke-Step 'Wait for cloud-init completion on all nodes' {
        foreach ($address in $nodeAddresses) {
            Invoke-SshCommand -User $sshUser -HostName $address -Command 'cloud-init status --wait'
        }
    }

    if (-not $SkipClusterBootstrap) {
        Invoke-Step 'Clone branch and bootstrap Kubernetes, platform add-ons, Istio, Bookinfo, GitOps, and validation' {
            $remoteScript = Get-Content -LiteralPath 'scripts/automation/bootstrap-autonomous-lab.sh' -Raw
            $workerHostValue = $workerAddresses -join ' '
            $remoteCommand = "REPO_URL='$RepoUrl' REPO_BRANCH='$RepoBranch' SSH_USER='$sshUser' CONTROL_HOST='$controlAddress' WORKER_HOSTS='$workerHostValue' bash -s"
            $remoteScript | & ssh -A -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=10 -o ServerAliveCountMax=12 "$sshUser@$controlAddress" $remoteCommand
            if ($LASTEXITCODE -ne 0) {
                throw "Remote autonomous bootstrap failed with exit code $LASTEXITCODE"
            }
        }
    }

    Write-Step 'Autonomous Hyper-V lab flow completed'
} finally {
    Pop-Location
}
