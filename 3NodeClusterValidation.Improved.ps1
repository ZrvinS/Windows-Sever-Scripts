<#
.SYNOPSIS
    Validates whether remote clusters contain at least three nodes and exports the results.

.DESCRIPTION
    This script is an improved version of 3NodeClusterValidation.ps1.
    It reads target servers from a file or accepts them directly through parameters,
    validates connectivity, establishes remote PowerShell sessions, retrieves cluster node data,
    and exports a structured report. CSV output is supported by default.

.PARAMETER ServerListPath
    Path to a text file containing one server name per line.
    Defaults to '.\servers.txt'.

.PARAMETER ComputerName
    Optional list of server names. If provided, this overrides ServerListPath.

.PARAMETER OutputPath
    Path to the output report file.
    Defaults to '.\ClusterNodesReport.csv'.

.PARAMETER Append
    Appends results to the output file instead of overwriting it.

.PARAMETER SkipPingTest
    Skips the pre-check ICMP connectivity test and attempts remoting directly.

.PARAMETER IncludeTimestamp
    Adds a CollectionTime property to each output object.

.EXAMPLE
    .\3NodeClusterValidation.Improved.ps1

.EXAMPLE
    .\3NodeClusterValidation.Improved.ps1 -ComputerName node01,node02 -Verbose

.EXAMPLE
    .\3NodeClusterValidation.Improved.ps1 -ServerListPath .\servers.txt -OutputPath .\reports\ClusterNodesReport.csv -IncludeTimestamp
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerListPath = ".\servers.txt",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = ".\ClusterNodesReport.csv",

    [Parameter()]
    [switch]$Append,

    [Parameter()]
    [switch]$SkipPingTest,

    [Parameter()]
    [switch]$IncludeTimestamp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TargetServers {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string[]]$Names
    )

    if ($Names -and $Names.Count -gt 0) {
        return $Names |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_.Trim() } |
            Select-Object -Unique
    }

    if (-not (Test-Path -Path $Path)) {
        throw "Server list file not found: $Path"
    }

    $servers = Get-Content -Path $Path -ErrorAction Stop |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() } |
        Select-Object -Unique

    if (-not $servers -or $servers.Count -eq 0) {
        throw "No valid server names were found in: $Path"
    }

    return $servers
}

function Test-ServerReachability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Server
    )

    try {
        return [bool](Test-Connection -ComputerName $Server -Count 1 -Quiet -ErrorAction Stop)
    }
    catch {
        return $false
    }
}

function Get-ThreeNodeClusterValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter()]
        [switch]$BypassPing,

        [Parameter()]
        [switch]$Timestamp
    )

    $reachable = $true
    if (-not $BypassPing) {
        $reachable = Test-ServerReachability -Server $Server
    }

    if (-not $reachable) {
        $result = [PSCustomObject]@{
            ComputerName    = $Server
            Reachable       = $false
            QueryStatus     = 'Failed'
            ClusterNode1    = $null
            ClusterNode2    = $null
            ClusterNode3    = $null
            NodeCount       = 0
            IsThreeNode     = $false
            ErrorMessage    = 'Server not reachable by ICMP ping.'
        }

        if ($Timestamp) {
            $result | Add-Member -NotePropertyName CollectionTime -NotePropertyValue (Get-Date)
        }

        return $result
    }

    $session = $null
    try {
        Write-Verbose "Creating remote session to $Server"
        $session = New-PSSession -ComputerName $Server -ErrorAction Stop

        $clusterResult = Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
            $clusterNames = Get-ClusterNode | Select-Object -ExpandProperty Name
            $nodeCount = @($clusterNames).Count

            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                ClusterNode1 = if ($nodeCount -ge 1) { $clusterNames[0] } else { $null }
                ClusterNode2 = if ($nodeCount -ge 2) { $clusterNames[1] } else { $null }
                ClusterNode3 = if ($nodeCount -ge 3) { $clusterNames[2] } else { $null }
                NodeCount    = $nodeCount
                IsThreeNode  = ($nodeCount -ge 3)
            }
        }

        $result = [PSCustomObject]@{
            ComputerName = $clusterResult.ComputerName
            Reachable    = $true
            QueryStatus  = 'Success'
            ClusterNode1 = $clusterResult.ClusterNode1
            ClusterNode2 = $clusterResult.ClusterNode2
            ClusterNode3 = $clusterResult.ClusterNode3
            NodeCount    = $clusterResult.NodeCount
            IsThreeNode  = $clusterResult.IsThreeNode
            ErrorMessage = $null
        }

        if ($Timestamp) {
            $result | Add-Member -NotePropertyName CollectionTime -NotePropertyValue (Get-Date)
        }

        return $result
    }
    catch {
        $result = [PSCustomObject]@{
            ComputerName = $Server
            Reachable    = $reachable
            QueryStatus  = 'Failed'
            ClusterNode1 = $null
            ClusterNode2 = $null
            ClusterNode3 = $null
            NodeCount    = 0
            IsThreeNode  = $false
            ErrorMessage = $_.Exception.Message
        }

        if ($Timestamp) {
            $result | Add-Member -NotePropertyName CollectionTime -NotePropertyValue (Get-Date)
        }

        return $result
    }
    finally {
        if ($session) {
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }
}

try {
    $servers = Get-TargetServers -Path $ServerListPath -Names $ComputerName
    $results = foreach ($server in $servers) {
        Get-ThreeNodeClusterValidation -Server $server -BypassPing:$SkipPingTest -Timestamp:$IncludeTimestamp -Verbose:$VerbosePreference
    }

    $outputDirectory = Split-Path -Path $OutputPath -Parent
    if ($outputDirectory -and -not (Test-Path -Path $outputDirectory)) {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    }

    if ($OutputPath.ToLowerInvariant().EndsWith('.csv')) {
        if ($Append -and (Test-Path -Path $OutputPath)) {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation -Append
        }
        else {
            $results | Export-Csv -Path $OutputPath -NoTypeInformation
        }
    }
    else {
        $outFileParams = @{
            FilePath = $OutputPath
            Force    = $true
        }

        if ($Append) {
            $outFileParams['Append'] = $true
        }

        $results |
            Format-Table ComputerName, QueryStatus, NodeCount, ClusterNode1, ClusterNode2, ClusterNode3, IsThreeNode, ErrorMessage -AutoSize |
            Out-String -Width 4096 |
            Out-File @outFileParams
    }

    $results
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
