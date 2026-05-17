<#
.SYNOPSIS
    Collects cluster group ownership and status information from one or more remote servers.

.DESCRIPTION
    This script is an improved version of ClusterNodeValidation.ps1.
    It reads server names from a text file or accepts them through the -ComputerName parameter,
    connects to each target using PowerShell remoting, retrieves cluster group details, and
    returns structured results.

    The script improves the original by:
    - adding parameter support
    - validating inputs
    - using structured output objects instead of unstructured pipeline output
    - handling remoting errors cleanly
    - writing optional report files
    - avoiding variable misuse and property name typos
    - returning a per-server success/failure status

.PARAMETER ServerListPath
    Path to a text file that contains one server name per line.
    Defaults to '.\Servers.txt'.

.PARAMETER ComputerName
    Optional list of server names. If provided, this overrides ServerListPath.

.PARAMETER OutputPath
    Path to the output report file.
    Defaults to '.\ClusterNodeResult.txt'.

.PARAMETER Append
    Appends results to the output file instead of overwriting it.

.PARAMETER IncludeTimestamp
    Adds a CollectionTime property to each result object.

.EXAMPLE
    .\ClusterNodeValidation.Improved.ps1

    Reads server names from .\Servers.txt and writes a report to .\ClusterNodeResult.txt.

.EXAMPLE
    .\ClusterNodeValidation.Improved.ps1 -ComputerName node01,node02 -Verbose

    Queries the specified remote servers directly and prints verbose progress messages.

.EXAMPLE
    .\ClusterNodeValidation.Improved.ps1 -ServerListPath .\MyServers.txt -OutputPath .\reports\ClusterReport.csv

    Reads servers from MyServers.txt and writes the result set to the specified report path.

.NOTES
    Requirements:
    - PowerShell remoting must be enabled on target systems.
    - The executing identity must have permission to run Get-ClusterGroup remotely.
    - Failover Clustering tools/cmdlets must be available on the target system.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerListPath = ".\Servers.txt",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = ".\ClusterNodeResult.txt",

    [Parameter()]
    [switch]$Append,

    [Parameter()]
    [switch]$IncludeTimestamp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TargetServers {
    [CmdletBinding()]
    param (
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

    $serversFromFile = Get-Content -Path $Path -ErrorAction Stop |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() } |
        Select-Object -Unique

    if (-not $serversFromFile -or $serversFromFile.Count -eq 0) {
        throw "No valid server names were found in: $Path"
    }

    return $serversFromFile
}

function Get-ClusterNodeValidationResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter()]
        [switch]$Timestamp
    )

    try {
        Write-Verbose "Connecting to $Server"

        $remoteResults = Invoke-Command -ComputerName $Server -ErrorAction Stop -ScriptBlock {
            $clusterGroups = Get-ClusterGroup | Select-Object Name, OwnerNode, State

            foreach ($group in $clusterGroups) {
                [PSCustomObject]@{
                    ClusterGroupName = $group.Name
                    OwnerNode        = $group.OwnerNode
                    GroupState       = $group.State
                }
            }
        }

        if (-not $remoteResults) {
            $emptyResult = [PSCustomObject]@{
                ComputerName     = $Server
                Reachable        = $true
                QueryStatus      = 'NoData'
                ClusterGroupName = $null
                OwnerNode        = $null
                GroupState       = $null
                ErrorMessage     = 'No cluster group data was returned.'
            }

            if ($Timestamp) {
                $emptyResult | Add-Member -NotePropertyName CollectionTime -NotePropertyValue (Get-Date)
            }

            return $emptyResult
        }

        foreach ($item in $remoteResults) {
            $resultObject = [PSCustomObject]@{
                ComputerName     = $Server
                Reachable        = $true
                QueryStatus      = 'Success'
                ClusterGroupName = $item.ClusterGroupName
                OwnerNode        = $item.OwnerNode
                GroupState       = $item.GroupState
                ErrorMessage     = $null
            }

            if ($Timestamp) {
                $resultObject | Add-Member -NotePropertyName CollectionTime -NotePropertyValue (Get-Date)
            }

            $resultObject
        }
    }
    catch {
        $failedResult = [PSCustomObject]@{
            ComputerName     = $Server
            Reachable        = $false
            QueryStatus      = 'Failed'
            ClusterGroupName = $null
            OwnerNode        = $null
            GroupState       = $null
            ErrorMessage     = $_.Exception.Message
        }

        if ($Timestamp) {
            $failedResult | Add-Member -NotePropertyName CollectionTime -NotePropertyValue (Get-Date)
        }

        return $failedResult
    }
}

try {
    $servers = Get-TargetServers -Path $ServerListPath -Names $ComputerName
    Write-Verbose ("Resolved {0} server(s) for processing." -f $servers.Count)

    $results = foreach ($server in $servers) {
        Get-ClusterNodeValidationResult -Server $server -Timestamp:$IncludeTimestamp -Verbose:$VerbosePreference
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
            Format-Table ComputerName, QueryStatus, ClusterGroupName, OwnerNode, GroupState, ErrorMessage -AutoSize |
            Out-String -Width 4096 |
            Out-File @outFileParams
    }

    $results
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
