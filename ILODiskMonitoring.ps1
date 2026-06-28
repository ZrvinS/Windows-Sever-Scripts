Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Monitors HPE iLO logical drive health and logs degraded/unhealthy servers to a file.

.DESCRIPTION
- Reads iLO addresses from ilolist.txt (one per line)
- Connects to each iLO using HPEiLOCmdlets
- Checks Smart Array logical drive health/state
- Writes ONLY degraded/unhealthy findings to a log file (CSV by default)

REQUIREMENTS
- HPEiLOCmdlets installed (e.g. hpeilocmdlets 4.4.0)
- Network access to iLOs

NOTES
- This script is intended to be scheduled (Task Scheduler) to run periodically.
- Credentials are configurable below; for production use prefer an encrypted credential file.

#>

# -----------------------------
# Configuration
# -----------------------------

# Folder where ilolist.txt is located and where logs will be written.
# Default: script directory
# If the script is run in a context where $PSCommandPath is empty (some hosts),
# fall back to current directory.
$BasePath = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { (Get-Location).Path }

# Input file containing iLO addresses (one per line)
$IloListPath = Join-Path $BasePath 'ilolist.txt'

# Output log file (CSV). Will be created if missing.
$LogPath = Join-Path $BasePath 'DegradedDisks.csv'

# Optional: also write a human-readable text log
$TextLogPath = Join-Path $BasePath 'DegradedDisks.log'

# Module path (adjust if your version differs)
$HpeIloModulePath = 'C:\Program Files\WindowsPowerShell\Modules\hpeilocmdlets.4.4.0\HPEiLOCmdlets.psd1'

# Credentials (RECOMMENDED: replace with Get-Credential / Import-Clixml approach)
$IloUser = 'Admin'
$IloPassword = 'HPAdmin@10001'

# If $true, ignore cert issues for iLO HTTPS
$DisableCertAuth = $true

# What to consider degraded:
# If any logical drive status is not in this set, it will be logged.
$HealthyStatuses = @(
  'OK',
  'Ok',
  'Good',
  'Normal',
  'Healthy'
)

# -----------------------------
# Helpers
# -----------------------------

function Import-HpeIloModule {
  if (Get-Module -ListAvailable -Name 'HPEiLOCmdlets' | Out-Null) {
    Import-Module HPEiLOCmdlets -ErrorAction SilentlyContinue
  }

  if (-not (Get-Module -Name 'HPEiLOCmdlets')) {
    if (Test-Path $HpeIloModulePath) {
      Import-Module $HpeIloModulePath
    } else {
      throw "HPEiLOCmdlets module not found. Adjust `$HpeIloModulePath or install the module."
    }
  }
}

function Normalize-StatusString {
  param(
    [Parameter(Mandatory)]
    [AllowNull()]
    [object]$Value
  )

  if ($null -eq $Value) { return '' }

  # Some cmdlets return complex objects; fall back to string.
  $s = [string]$Value
  return $s.Trim()
}

function Is-HealthyStatus {
  param(
    [Parameter(Mandatory)]
    [string]$Status
  )

  if ([string]::IsNullOrWhiteSpace($Status)) { return $false }
  return $HealthyStatuses -contains $Status
}

function Write-TextLogLine {
  param(
    [Parameter(Mandatory)]
    [string]$Line
  )
  $Line | Out-File -FilePath $TextLogPath -Append -Encoding utf8
}

# -----------------------------
# Main
# -----------------------------

Import-HpeIloModule

if (-not (Test-Path $IloListPath)) {
  throw "Input file not found: $IloListPath"
}

$ilos = Get-Content -Path $IloListPath | Where-Object {
  -not [string]::IsNullOrWhiteSpace($_) -and $_ -notmatch '^\s*#'
} | ForEach-Object { $_.Trim() }

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Write-TextLogLine "[$timestamp] Starting iLO disk health scan."

# Keep it simple: write a line per degraded iLO to a text file.
# Log format: timestamp | ilo | health | state
foreach ($ilo in $ilos) {
  try {
    $connParams = @{
      Address  = $ilo
      Username = $IloUser
      Password = $IloPassword
    }
    if ($DisableCertAuth) { $connParams.DisableCertificateAuthentication = $true }

    $iloConn = Connect-HPEiLO @connParams
    $controllerInfo = Get-HPEiLOSmartArrayStorageController -Connection $iloConn

    $health = [string]$controllerInfo.Controllers.LogicalDrives.Status
    $state  = [string]$controllerInfo.Controllers.State

    $health = $health.Trim()
    $state  = $state.Trim()

    $isDegraded = ($HealthyStatuses -notcontains $health) -or ($HealthyStatuses -notcontains $state)

    if ($isDegraded) {
      $line = "{0} | {1} | Health={2} | State={3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ilo, $health, $state
      $line | Out-File -FilePath $TextLogPath -Append -Encoding utf8
    }

    try { Disconnect-HPEiLO -Connection $iloConn | Out-Null } catch { }
  } catch {
    $err = $_.Exception.Message
    $line = "{0} | {1} | ERROR | {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ilo, $err
    $line | Out-File -FilePath $TextLogPath -Append -Encoding utf8
  }
}

Write-TextLogLine ("[{0}] Completed." -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
