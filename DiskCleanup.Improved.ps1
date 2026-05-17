<#
.SYNOPSIS
    Cleans temporary files, logs, caches, and recycle bin content on a local Windows server.

.DESCRIPTION
    This script is an improved version of DiskCleanup.ps1.
    It performs controlled local disk cleanup operations for common temporary paths, optional user
    temp locations, IIS logs, ConfigMgr cache, and recycle bin content. It supports transcript logging,
    WhatIf behavior, structured result output, and configurable cleanup targets.

.PARAMETER CleanupPaths
    One or more filesystem paths or wildcard patterns to clean.

.PARAMETER IncludeUserTemp
    Cleans files under user temp folders.

.PARAMETER IncludeTemporaryInternetFiles
    Cleans files under user temporary internet files folders.

.PARAMETER IncludeIisLogs
    Cleans IIS log folders.

.PARAMETER IncludeCcmCache
    Cleans Microsoft Configuration Manager client cache if available.

.PARAMETER IncludeRecycleBin
    Cleans recycle bin content.

.PARAMETER DelProfPath
    Optional path to delprof2.exe.

.PARAMETER DelProfDays
    Profile age in days for delprof2 cleanup.
    Defaults to 60.

.PARAMETER TranscriptPath
    Path to the transcript log file.
    Defaults to a timestamped file under C:\Windows\Temp.

.EXAMPLE
    .\DiskCleanup.Improved.ps1

.EXAMPLE
    .\DiskCleanup.Improved.ps1 -IncludeIisLogs -IncludeRecycleBin -Verbose

.EXAMPLE
    .\DiskCleanup.Improved.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [string[]]$CleanupPaths = @(
        'C:\Temp\',
        'C:\Windows\*.log',
        'C:\Windows\Temp\',
        'C:\Windows\Logs\',
        'C:\hprepair_ALFRDCSIM01*',
        'C:\Windows\SoftwareDistribution\',
        'C:\Windows\CCM\logs\',
        'C:\Windows\dd_*.txt',
        'C:\Windows\hprepair*',
        'C:\Windows\SET*.tmp',
        'C:\BrightStor SRM Data\',
        'C:\inetpub\logs\LogFiles\',
        'C:\Program Files\CA\ARCserve Backup Client Agent for Windows\LOG\',
        'C:\Program Files (x86)\CA\ARCserve Backup Agent for Open Files\LOGS\',
        'C:\PerfLogs\',
        'C:\Windows\MEMORY.DMP'
    ),

    [Parameter()]
    [switch]$IncludeUserTemp,

    [Parameter()]
    [switch]$IncludeTemporaryInternetFiles,

    [Parameter()]
    [switch]$IncludeIisLogs,

    [Parameter()]
    [switch]$IncludeCcmCache,

    [Parameter()]
    [switch]$IncludeRecycleBin,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DelProfPath = 'C:\Scripts\delprof2.exe',

    [Parameter()]
    [ValidateRange(1, 3650)]
    [int]$DelProfDays = 60,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TranscriptPath = ("C:\Windows\Temp\DiskCleanup_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-PathContentSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PathPattern
    )

    try {
        $items = Get-ChildItem -Path $PathPattern -Force -Recurse -ErrorAction SilentlyContinue
        if (-not $items) {
            return [PSCustomObject]@{
                TargetPath    = $PathPattern
                Result        = 'NoData'
                RemovedCount  = 0
                ErrorMessage  = $null
            }
        }

        $removedCount = 0
        foreach ($item in $items) {
            if ($PSCmdlet.ShouldProcess($item.FullName, 'Remove item')) {
                Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                $removedCount++
            }
        }

        return [PSCustomObject]@{
            TargetPath    = $PathPattern
            Result        = 'Success'
            RemovedCount  = $removedCount
            ErrorMessage  = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            TargetPath    = $PathPattern
            Result        = 'Failed'
            RemovedCount  = 0
            ErrorMessage  = $_.Exception.Message
        }
    }
}

function Invoke-DelProfCleanup {
    [CmdletBinding()]
    param(
        [string]$ExecutablePath,
        [int]$ProfileDays
    )

    if (-not (Test-Path -Path $ExecutablePath)) {
        return [PSCustomObject]@{
            Action       = 'DelProf2'
            Result       = 'Skipped'
            ErrorMessage = "Executable not found: $ExecutablePath"
        }
    }

    try {
        $arguments = "/u /d:$ProfileDays"
        if ($PSCmdlet.ShouldProcess($ExecutablePath, "Execute delprof2 with arguments $arguments")) {
            Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -Wait -ErrorAction Stop
        }

        return [PSCustomObject]@{
            Action       = 'DelProf2'
            Result       = 'Success'
            ErrorMessage = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            Action       = 'DelProf2'
            Result       = 'Failed'
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Clear-CcmCache {
    [CmdletBinding()]
    param()

    try {
        $resourceManager = New-Object -ComObject 'UIResource.UIResourceMgr'
        $cacheInfo = $resourceManager.GetCacheInfo()
        $elements = @($cacheInfo.GetCacheElements())

        foreach ($element in $elements) {
            if ($PSCmdlet.ShouldProcess($element.CacheElementID, 'Delete ConfigMgr cache element')) {
                $cacheInfo.DeleteCacheElement($element.CacheElementID)
            }
        }

        return [PSCustomObject]@{
            Action       = 'CCMCache'
            Result       = 'Success'
            RemovedCount = $elements.Count
            ErrorMessage = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            Action       = 'CCMCache'
            Result       = 'Failed'
            RemovedCount = 0
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Clear-RecycleBinContent {
    [CmdletBinding()]
    param()

    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.Namespace(0xA)
        $items = @($recycleBin.Items())

        foreach ($item in $items) {
            if ($PSCmdlet.ShouldProcess($item.Path, 'Remove recycle bin item')) {
                Remove-Item -Path $item.Path -Force -Recurse -ErrorAction SilentlyContinue
            }
        }

        return [PSCustomObject]@{
            Action       = 'RecycleBin'
            Result       = 'Success'
            RemovedCount = $items.Count
            ErrorMessage = $null
        }
    }
    catch {
        return [PSCustomObject]@{
            Action       = 'RecycleBin'
            Result       = 'Failed'
            RemovedCount = 0
            ErrorMessage = $_.Exception.Message
        }
    }
}

$transcriptStarted = $false
try {
    Start-Transcript -Path $TranscriptPath -ErrorAction Stop
    $transcriptStarted = $true

    $results = New-Object System.Collections.Generic.List[object]

    $results.Add((Invoke-DelProfCleanup -ExecutablePath $DelProfPath -ProfileDays $DelProfDays))

    foreach ($path in $CleanupPaths) {
        $results.Add((Remove-PathContentSafely -PathPattern $path))
    }

    if ($IncludeUserTemp) {
        $results.Add((Remove-PathContentSafely -PathPattern 'C:\Users\*\AppData\Local\Temp\*'))
    }

    if ($IncludeTemporaryInternetFiles) {
        $results.Add((Remove-PathContentSafely -PathPattern 'C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*'))
    }

    if ($IncludeIisLogs) {
        $results.Add((Remove-PathContentSafely -PathPattern 'C:\inetpub\logs\LogFiles\*'))
    }

    if ($IncludeCcmCache) {
        $results.Add((Clear-CcmCache))
    }

    if ($IncludeRecycleBin) {
        $results.Add((Clear-RecycleBinContent))
    }

    $results
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
}
