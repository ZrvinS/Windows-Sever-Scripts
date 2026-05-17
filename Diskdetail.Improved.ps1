<#
.SYNOPSIS
    Collects disk size and free space information from one or more servers.

.DESCRIPTION
    Improved version of Diskdetail.ps1. Reads server names from a file or parameters,
    validates connectivity, queries logical disk information remotely, and exports structured
    results. CSV output is supported by default for reporting.

.PARAMETER ServerListPath
    Path to the server list file. Defaults to '.\servers.txt'.

.PARAMETER ComputerName
    Optional list of computer names. Overrides ServerListPath when provided.

.PARAMETER OutputPath
    Output report path. Defaults to '.\DiskDetailReport.csv'.

.PARAMETER Append
    Appends to an existing report file.

.PARAMETER SkipPingTest
    Skips ICMP reachability checks before querying the target.

.EXAMPLE
    .\Diskdetail.Improved.ps1

.EXAMPLE
    .\Diskdetail.Improved.ps1 -ComputerName server01,server02 -Verbose
#>

[CmdletBinding()]
param(
    [string]$ServerListPath = '.\servers.txt',
    [string[]]$ComputerName,
    [string]$OutputPath = '.\DiskDetailReport.csv',
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

function Get-DiskDetailForServer {
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
            ComputerName   = $Server
            DriveId        = $null
            SizeGB         = $null
            FreeSpaceGB    = $null
            QueryStatus    = 'Failed'
            ErrorMessage   = 'Server not reachable by ICMP ping.'
        }
    }

    try {
        Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Server -ErrorAction Stop |
            Select-Object @{Name='ComputerName';Expression={$_.SystemName}},
                          @{Name='DriveId';Expression={$_.DeviceID}},
                          @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                          @{Name='FreeSpaceGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                          @{Name='QueryStatus';Expression={'Success'}},
                          @{Name='ErrorMessage';Expression={$null}}
    }
    catch {
        [PSCustomObject]@{
            ComputerName   = $Server
            DriveId        = $null
            SizeGB         = $null
            FreeSpaceGB    = $null
            QueryStatus    = 'Failed'
            ErrorMessage   = $_.Exception.Message
        }
    }
}

try {
    $servers = Get-TargetServers -Path $ServerListPath -Names $ComputerName
    $results = foreach ($server in $servers) {
        Get-DiskDetailForServer -Server $server -BypassPing:$SkipPingTest
    }

    Export-StructuredData -Data $results -Path $OutputPath -AppendMode:$Append
    $results
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
