<#
.SYNOPSIS
    Collects BitLocker drive protection information from one or more remote servers.

.DESCRIPTION
    Improved version of GetBitbockedDrives.ps1. Reads server names from file or parameter,
    queries BitLocker volume details remotely, and exports structured results. CSV output is
    supported by default.

.PARAMETER ServerListPath
    Path to the input server list file. Defaults to '.\servers.txt'.

.PARAMETER ComputerName
    Optional list of server names. Overrides ServerListPath.

.PARAMETER OutputPath
    Report path. Defaults to '.\BitLockerDriveReport.csv'.

.PARAMETER Append
    Appends to the report file.

.PARAMETER SkipPingTest
    Skips ICMP reachability tests before remoting.

.EXAMPLE
    .\GetBitbockedDrives.Improved.ps1
#>

[CmdletBinding()]
param(
    [string]$ServerListPath = '.\servers.txt',
    [string[]]$ComputerName,
    [string]$OutputPath = '.\BitLockerDriveReport.csv',
    [switch]$Append,
    [switch]$SkipPingTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TargetServers {
    param([string]$Path,[string[]]$Names)

    if ($Names -and $Names.Count -gt 0) {
        return $Names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() } | Select-Object -Unique
    }

    if (-not (Test-Path -Path $Path)) {
        throw "Server list file not found: $Path"
    }

    $servers = Get-Content -Path $Path -ErrorAction Stop |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() } |
        Select-Object -Unique

    if (-not $servers) {
        throw "No valid server names found in: $Path"
    }

    return $servers
}

function Export-StructuredData {
    param([object[]]$Data,[string]$Path,[switch]$AppendMode)

    $directory = Split-Path -Path $Path -Parent
    if ($directory -and -not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    if ($Path.ToLowerInvariant().EndsWith('.csv')) {
        if ($AppendMode -and (Test-Path -Path $Path)) {
            $Data | Export-Csv -Path $Path -NoTypeInformation -Append
        } else {
            $Data | Export-Csv -Path $Path -NoTypeInformation
        }
    } else {
        $outFileParams = @{ FilePath = $Path; Force = $true }
        if ($AppendMode) { $outFileParams['Append'] = $true }
        $Data | Format-Table -AutoSize | Out-String -Width 4096 | Out-File @outFileParams
    }
}

function Get-BitLockerInfoForServer {
    param([string]$Server,[switch]$BypassPing)

    $reachable = $true
    if (-not $BypassPing) {
        try {
            $reachable = Test-Connection -ComputerName $Server -Count 1 -Quiet -ErrorAction Stop
        } catch {
            $reachable = $false
        }
    }

    if (-not $reachable) {
        return [PSCustomObject]@{
            ComputerName         = $Server
            VolumeType           = $null
            MountPoint           = $null
            EncryptionPercentage = $null
            ProtectionStatus     = $null
            QueryStatus          = 'Failed'
            ErrorMessage         = 'Server not reachable by ICMP ping.'
        }
    }

    try {
        Invoke-Command -ComputerName $Server -ErrorAction Stop -ScriptBlock {
            Get-BitLockerVolume | Select-Object @{Name='ComputerName';Expression={$env:COMPUTERNAME}},
                                              VolumeType,
                                              MountPoint,
                                              EncryptionPercentage,
                                              ProtectionStatus,
                                              @{Name='QueryStatus';Expression={'Success'}},
                                              @{Name='ErrorMessage';Expression={$null}}
        }
    }
    catch {
        [PSCustomObject]@{
            ComputerName         = $Server
            VolumeType           = $null
            MountPoint           = $null
            EncryptionPercentage = $null
            ProtectionStatus     = $null
            QueryStatus          = 'Failed'
            ErrorMessage         = $_.Exception.Message
        }
    }
}

try {
    $servers = Get-TargetServers -Path $ServerListPath -Names $ComputerName
    $results = foreach ($server in $servers) {
        Get-BitLockerInfoForServer -Server $server -BypassPing:$SkipPingTest
    }

    Export-StructuredData -Data $results -Path $OutputPath -AppendMode:$Append
    $results
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
