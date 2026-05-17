<#
.SYNOPSIS
    Collects firmware inventory information from one or more HPE iLO endpoints.

.DESCRIPTION
    Improved version of FirmwareVersionFromILO.ps1. Reads iLO addresses from a file or parameter,
    imports the HPE iLO module, connects to each endpoint, retrieves firmware inventory details,
    and exports structured results. CSV output is supported by default.

.PARAMETER ILOListPath
    Path to a text file containing one iLO address per line.
    Defaults to '.\ilolist.txt'.

.PARAMETER Address
    Optional list of iLO addresses. Overrides ILOListPath when provided.

.PARAMETER UserName
    iLO user name.

.PARAMETER Password
    iLO password as plain text. Prefer secure handling in the target environment.

.PARAMETER ModulePath
    Path to the HPE iLO PowerShell module manifest.

.PARAMETER OutputPath
    Output report path. Defaults to '.\IloFirmwareVersionReport.csv'.

.PARAMETER Append
    Appends to the output file if it exists.

.EXAMPLE
    .\FirmwareVersionFromILO.Improved.ps1 -UserName admin -Password secret
#>

[CmdletBinding()]
param(
    [string]$ILOListPath = '.\ilolist.txt',
    [string[]]$Address,
    [Parameter(Mandatory)]
    [string]$UserName,
    [Parameter(Mandatory)]
    [string]$Password,
    [string]$ModulePath = 'C:\Program Files\WindowsPowerShell\Modules\hpeilocmdlets.4.4.0\HPEiLOCmdlets.psd1',
    [string]$OutputPath = '.\IloFirmwareVersionReport.csv',
    [switch]$Append
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TargetAddresses {
    param([string]$Path,[string[]]$Names)

    if ($Names -and $Names.Count -gt 0) {
        return $Names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() } | Select-Object -Unique
    }

    if (-not (Test-Path -Path $Path)) {
        throw "iLO list file not found: $Path"
    }

    $items = Get-Content -Path $Path -ErrorAction Stop |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() } |
        Select-Object -Unique

    if (-not $items) {
        throw "No valid iLO addresses found in: $Path"
    }

    return $items
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

try {
    if (-not (Test-Path -Path $ModulePath)) {
        throw "HPE iLO module not found: $ModulePath"
    }

    Import-Module $ModulePath -ErrorAction Stop
    $addresses = Get-TargetAddresses -Path $ILOListPath -Names $Address

    $results = foreach ($ilo in $addresses) {
        try {
            $connection = Connect-HPEiLO -Address $ilo -Username $UserName -Password $Password -DisableCertificateAuthentication -ErrorAction Stop
            $firmware = Get-HPEiLOFirmwareInventory -Connection $connection -ErrorAction Stop

            foreach ($item in $firmware.FirmwareInformation) {
                [PSCustomObject]@{
                    ILOAddress    = $ilo
                    Name          = $item.Name
                    Version       = $item.Version
                    Location      = $item.Location
                    Status        = 'Success'
                    ErrorMessage  = $null
                }
            }
        }
        catch {
            [PSCustomObject]@{
                ILOAddress    = $ilo
                Name          = $null
                Version       = $null
                Location      = $null
                Status        = 'Failed'
                ErrorMessage  = $_.Exception.Message
            }
        }
    }

    Export-StructuredData -Data $results -Path $OutputPath -AppendMode:$Append
    $results
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
