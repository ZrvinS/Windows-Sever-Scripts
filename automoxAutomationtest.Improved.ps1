<#
.SYNOPSIS
    Collects local service, filesystem, process, and installed software information for automation validation.

.DESCRIPTION
    This script is an improved version of automoxAutomationtest.ps1.
    It validates local conditions, optionally creates a test directory on a UNC path, collects
    service/process/application information, and exports structured results. CSV output is supported
    for report-style data.

.PARAMETER ServiceName
    Name of the Windows service to inspect.
    Defaults to 'BITS'.

.PARAMETER DirectoryName
    Name of the directory to create on the target path.
    Defaults to 'AmitTest'.

.PARAMETER DirectoryPath
    Parent path where the directory should be created.
    Defaults to '\\Mcktorcfps01\wksmgmt\Public\'.

.PARAMETER SoftwarePattern
    Display name pattern used to search the uninstall registry.
    Defaults to 'Quest Change*'.

.PARAMETER ProcessOutputPath
    Output file path for process inventory.
    Defaults to '.\ProcessReport.csv'.

.PARAMETER SoftwareOutputPath
    Output file path for installed software inventory.
    Defaults to '.\InstalledSoftwareReport.csv'.

.PARAMETER SkipDirectoryCreation
    Skips creation of the target directory.

.PARAMETER Append
    Appends to output CSV files if they already exist.

.EXAMPLE
    .\automoxAutomationtest.Improved.ps1

.EXAMPLE
    .\automoxAutomationtest.Improved.ps1 -ServiceName Spooler -DirectoryName ValidationFolder -Verbose

.EXAMPLE
    .\automoxAutomationtest.Improved.ps1 -SkipDirectoryCreation -ProcessOutputPath .\reports\Processes.csv -SoftwareOutputPath .\reports\Software.csv
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = 'BITS',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DirectoryName = 'AmitTest',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DirectoryPath = '\\Mcktorcfps01\wksmgmt\Public\',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SoftwarePattern = 'Quest Change*',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ProcessOutputPath = '.\ProcessReport.csv',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SoftwareOutputPath = '.\InstalledSoftwareReport.csv',

    [Parameter()]
    [switch]$SkipDirectoryCreation,

    [Parameter()]
    [switch]$Append
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Export-StructuredData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Data,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [switch]$AppendMode
    )

    $directory = Split-Path -Path $Path -Parent
    if ($directory -and -not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    if ($Path.ToLowerInvariant().EndsWith('.csv')) {
        if ($AppendMode -and (Test-Path -Path $Path)) {
            $Data | Export-Csv -Path $Path -NoTypeInformation -Append
        }
        else {
            $Data | Export-Csv -Path $Path -NoTypeInformation
        }
    }
    else {
        $outFileParams = @{
            FilePath = $Path
            Force    = $true
        }

        if ($AppendMode) {
            $outFileParams['Append'] = $true
        }

        $Data | Format-Table -AutoSize | Out-String -Width 4096 | Out-File @outFileParams
    }
}

function Get-InstalledApplication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $registryPaths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($path in $registryPaths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $Pattern } |
            Select-Object @{Name='ComputerName';Expression={$env:COMPUTERNAME}},
                          DisplayName,
                          DisplayVersion,
                          InstallDate,
                          Publisher
    }
}

try {
    $serviceResult = try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            CheckType    = 'Service'
            Name         = $service.Name
            DisplayName  = $service.DisplayName
            Status       = $service.Status
            StartType    = $service.StartType
            Result       = 'Success'
            Message      = $null
        }
    }
    catch {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            CheckType    = 'Service'
            Name         = $ServiceName
            DisplayName  = $null
            Status       = $null
            StartType    = $null
            Result       = 'Failed'
            Message      = $_.Exception.Message
        }
    }

    $directoryResult = if ($SkipDirectoryCreation) {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            CheckType    = 'DirectoryCreation'
            TargetPath   = Join-Path -Path $DirectoryPath -ChildPath $DirectoryName
            Result       = 'Skipped'
            Message      = 'Directory creation skipped by parameter.'
        }
    }
    else {
        try {
            $targetDirectory = Join-Path -Path $DirectoryPath -ChildPath $DirectoryName
            if (-not (Test-Path -Path $targetDirectory)) {
                New-Item -Name $DirectoryName -ItemType Directory -Path $DirectoryPath -ErrorAction Stop | Out-Null
                $message = 'Directory created.'
            }
            else {
                $message = 'Directory already exists.'
            }

            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                CheckType    = 'DirectoryCreation'
                TargetPath   = $targetDirectory
                Result       = 'Success'
                Message      = $message
            }
        }
        catch {
            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                CheckType    = 'DirectoryCreation'
                TargetPath   = Join-Path -Path $DirectoryPath -ChildPath $DirectoryName
                Result       = 'Failed'
                Message      = $_.Exception.Message
            }
        }
    }

    $processData = Get-Process -ErrorAction Stop |
        Select-Object @{Name='ComputerName';Expression={$env:COMPUTERNAME}},
                      Name,
                      CPU,
                      Id

    $softwareData = @(Get-InstalledApplication -Pattern $SoftwarePattern)
    if (-not $softwareData -or $softwareData.Count -eq 0) {
        $softwareData = @(
            [PSCustomObject]@{
                ComputerName   = $env:COMPUTERNAME
                DisplayName    = $null
                DisplayVersion = $null
                InstallDate    = $null
                Publisher      = $null
                Result         = 'NoMatch'
                Message        = "No installed application matched pattern '$SoftwarePattern'."
            }
        )
    }
    else {
        $softwareData = $softwareData | Select-Object *, @{Name='Result';Expression={'Success'}}, @{Name='Message';Expression={$null}}
    }

    Export-StructuredData -Data $processData -Path $ProcessOutputPath -AppendMode:$Append
    Export-StructuredData -Data $softwareData -Path $SoftwareOutputPath -AppendMode:$Append

    [PSCustomObject]@{
        ServiceCheck       = $serviceResult
        DirectoryCheck     = $directoryResult
        ProcessOutputPath  = $ProcessOutputPath
        SoftwareOutputPath = $SoftwareOutputPath
        ProcessCount       = @($processData).Count
        SoftwareMatchCount = @($softwareData | Where-Object { $_.Result -eq 'Success' }).Count
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
