<#
.SYNOPSIS
    Uninstalls existing Qualys Agent (if found) and installs a new version on remote servers.

.DESCRIPTION
    This script remotely manages Qualys Cloud Agent installations on a list of servers.
    It first attempts to find and uninstall any existing Qualys Agent by querying the registry.
    If an existing agent is found, it attempts a silent uninstallation.
    After ensuring no old agent is present (or if none was found), it copies new installation files
    to a temporary directory on the remote server and executes the Qualys Agent installer
    with parameters specified in a configuration file.
    The script processes servers in parallel, with a configurable throttle limit.
    All actions are logged to a transcript file.

.PARAMETER ServerListPath
    Specifies the path to a text file containing a list of server names (one per line)
    to process. Defaults to '.\servers.txt'.

.PARAMETER ConfigFilePath
    Specifies the path to a JSON configuration file containing Qualys installation parameters
    like QualysSourcePath, CustomerId, ActivationId, and WebServiceUri.
    Defaults to '.\qualys_config.json'.

.PARAMETER ThrottleLimit
    Specifies the maximum number of concurrent remote sessions for Invoke-Command.
    Defaults to 32.

.EXAMPLE
    .\QualysUninstall.ps1 -ServerListPath "C:\Path\To\MyServers.txt" -ConfigFilePath "C:\Path\To\QualysConfig.json" -ThrottleLimit 16
    This command runs the script using 'MyServers.txt' for the server list, 'QualysConfig.json' for
    Qualys settings, and processes up to 16 servers concurrently.

.EXAMPLE
    .\QualysUninstall.ps1 -Verbose
    This command runs the script with default paths and throttle limit, and displays verbose
    logging output for detailed operation tracking.

.NOTE
    Ensure the configuration file specified by -ConfigFilePath (default: qualys_config.json) 
    is adequately secured as it contains sensitive Qualys identifiers.
#>
param (
    [int]$ThrottleLimit = 32,
    [string]$ConfigFilePath = ".\qualys_config.json",
    [string]$ServerListPath = ".\servers.txt"
)

Start-Transcript -Path ".\QualysUninstall_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Validate and load server list
if (-not (Test-Path $ServerListPath)) {
    Write-Error "Server list file '$ServerListPath' not found."
    if ($Global:IsTranscribing) { Stop-Transcript }
    exit 1
}
$servers = Get-Content $ServerListPath -ErrorAction Stop
if ($servers.Count -eq 0) {
    Write-Error "Server list file '$ServerListPath' is empty or could not be read."
    if ($Global:IsTranscribing) { Stop-Transcript }
    exit 1
}

# Load configuration
$config = $null
if (Test-Path $ConfigFilePath) {
    try {
        $configContent = Get-Content $ConfigFilePath -Raw
        $config = $configContent | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Error "Error parsing configuration file '$ConfigFilePath': $($_.Exception.Message)"
        if ($Global:IsTranscribing) { Stop-Transcript }
        exit 1
    }
}
else {
    Write-Error "Configuration file '$ConfigFilePath' not found."
    if ($Global:IsTranscribing) { Stop-Transcript }
    exit 1
}

# Validate required configuration keys
$requiredKeys = @("QualysSourcePath", "CustomerId", "ActivationId", "WebServiceUri")
$missingKeys = @()
foreach ($key in $requiredKeys) {
    if (-not $config.PSObject.Properties.Name.Contains($key)) {
        $missingKeys += $key
    }
}

if ($missingKeys.Count -gt 0) {
    Write-Error "Configuration file '$ConfigFilePath' is missing the following required keys: $($missingKeys -join ', ')"
    if ($Global:IsTranscribing) { Stop-Transcript }
    exit 1
}

Invoke-Command -ComputerName $servers -ArgumentList $config -ScriptBlock {
    param($CurrentConfig) # Renamed to avoid potential conflict with $config if used globally in scriptblock

    $ErrorActionPreference = 'Stop'

    function Get-QualysInstallation {
        Write-Verbose "[$($env:COMPUTERNAME)] Searching for existing Qualys installation via registry..."
        $uninstallPaths = @(
            "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        foreach ($path in $uninstallPaths) {
            $registryKeys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | 
                            Where-Object { $_.DisplayName -like "Qualys*" -and $_.UninstallString }
            if ($registryKeys) {
                $foundApp = $registryKeys | Select-Object -First 1
                Write-Verbose "[$($env:COMPUTERNAME)] Found Qualys Application: $($foundApp.DisplayName), Version: $($foundApp.DisplayVersion)"
                return [PSCustomObject]@{
                    DisplayName     = $foundApp.DisplayName
                    DisplayVersion  = $foundApp.DisplayVersion
                    UninstallString = $foundApp.UninstallString
                }
            }
        }
        Write-Verbose "[$($env:COMPUTERNAME)] No Qualys application found via registry."
        return $null
    }

    function Remove-QualysApplication {
        param(
            [Parameter(Mandatory=$true)]
            [PSCustomObject]$QualysApp
        )
        
        Write-Verbose "[$($env:COMPUTERNAME)] Attempting to uninstall $($QualysApp.DisplayName)..."
        Write-Verbose "[$($env:COMPUTERNAME)] Uninstall String: $($QualysApp.UninstallString)"
        
        try {
            $uninstallString = $QualysApp.UninstallString
            $command = ""
            $arguments = ""

            if ($uninstallString.StartsWith('"')) {
                $endQuoteIndex = $uninstallString.IndexOf('"', 1)
                if ($endQuoteIndex -gt 0) {
                    $command = $uninstallString.Substring(0, $endQuoteIndex + 1).Trim('"')
                    if ($uninstallString.Length -gt ($endQuoteIndex + 1)) {
                        $arguments = $uninstallString.Substring($endQuoteIndex + 1).Trim()
                    }
                } else { $command = $uninstallString.Trim('"') }
            } else {
                $parts = $uninstallString -split ' ', 2
                $command = $parts[0].Trim('"')
                if ($parts.Length -gt 1) { $arguments = $parts[1].Trim() }
            }
            
            if ($command -match 'msiexec\.exe' -and $arguments -notmatch '/[qQ][nN]?' -and $arguments -notmatch '/[qQ][bB]') {
                $arguments += ' /qn /norestart'
            } elseif (($command -notmatch 'msiexec\.exe') -and ($arguments -notmatch '[/-][sS](ilent)?' -and $arguments -notmatch '[/-][qQ](uiet)?')) {
                 if ($arguments -notmatch '(/silent|/verysilent|/q|/quiet|/s)') {
                     $arguments = ($arguments + ' /S').Trim()
                 }
            }

            Write-Verbose "[$($env:COMPUTERNAME)] Executing uninstall: `"$command`" $arguments"
            Start-Process -FilePath $command -ArgumentList $arguments -Wait -ErrorAction Stop
            Write-Verbose "[$($env:COMPUTERNAME)] Uninstallation command for '$($QualysApp.DisplayName)' executed."

            # Verification step
            Write-Verbose "[$($env:COMPUTERNAME)] Verifying uninstallation of '$($QualysApp.DisplayName)'..."
            $stillExistsCheck = Get-QualysInstallation # Re-check using the same function
            if ($stillExistsCheck -and $stillExistsCheck.DisplayName -eq $QualysApp.DisplayName) {
                 Write-Warning "[$($env:COMPUTERNAME)] Application '$($QualysApp.DisplayName)' still detected in registry after uninstall attempt."
                 return $false
            } else {
                Write-Verbose "[$($env:COMPUTERNAME)] Uninstallation of '$($QualysApp.DisplayName)' verified via registry."
                return $true
            }
        }
        catch {
            Write-Error "[$($env:COMPUTERNAME)] Error during uninstallation of '$($QualysApp.DisplayName)': $($_.Exception.Message)"
            return $false
        }
    }

    function Install-QualysAgent {
        param(
            [Parameter(Mandatory=$true)]
            [object]$PassedConfig # Using 'object' type for flexibility, matches $config from ArgumentList
        )

        $sourceApp = $PassedConfig.QualysSourcePath
        $destinationpath = "C:\Temp" 

        try {
            Write-Verbose "[$($env:COMPUTERNAME)] Ensuring temp directory $destinationpath exists..."
            if (-Not (Test-Path $destinationpath)){
                New-Item -Path $destinationpath -ItemType Directory | Out-Null
                Write-Verbose "[$($env:COMPUTERNAME)] Temp directory created at $destinationpath"
            }
        }
        catch {
            Write-Error "[$($env:COMPUTERNAME)] Error creating temp directory $destinationpath : $($_.Exception.Message)"
            return $false
        }

        try {
            Write-Verbose "[$($env:COMPUTERNAME)] Copying Qualys installation files from $sourceApp to $destinationpath"
            Copy-Item -Path $sourceApp -Destination $destinationpath -Recurse -Force -ErrorAction Stop
            Write-Verbose "[$($env:COMPUTERNAME)] Qualys installation files copied to $destinationpath"
        }
        catch {
            Write-Error "[$($env:COMPUTERNAME)] Error copying Qualys installation files: $($_.Exception.Message)"
            return $false
        }

        try {
            Set-Location -Path $destinationpath
            Write-Verbose "[$($env:COMPUTERNAME)] Changed current location to $destinationpath"
            Write-Verbose "[$($env:COMPUTERNAME)] Starting Qualys Agent installation with CustomerId: $($PassedConfig.CustomerId)"
            & .\QualysCloudAgent.exe "CustomerId={$($PassedConfig.CustomerId)}" "ActivationId={$($PassedConfig.ActivationId)}" "WebServiceUri=$($PassedConfig.WebServiceUri)"
            Write-Verbose "[$($env:COMPUTERNAME)] Qualys Agent installation command executed."
            
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[$($env:COMPUTERNAME)] QualysCloudAgent.exe completed with exit code $LASTEXITCODE."
                return $false 
            }
            return $true
        }
        catch {
            Write-Error "[$($env:COMPUTERNAME)] Error during Qualys Agent installation: $($_.Exception.Message)"
            return $false
        }
    }

    # Initialize status variables
    $statusComputerName = $env:COMPUTERNAME
    $statusOverall = "Failed" # Default to Failed, set to Success at the end if all good
    $statusQualysUninstalled = $null # Can be $true, $false, or $null if not attempted/applicable
    $statusQualysInstalled = $false
    $statusMessage = ""

    try {
        # Main execution flow within ScriptBlock for each server
        Write-Verbose "[$statusComputerName] Starting Qualys Agent processing..."
        $qualysInfo = Get-QualysInstallation
        
        if ($qualysInfo) {
            $uninstalledResult = Remove-QualysApplication -QualysApp $qualysInfo
            $statusQualysUninstalled = $uninstalledResult
            if (-not $uninstalledResult) {
                $statusMessage = "Qualys uninstallation failed or was not verified. Skipping re-installation."
                Write-Warning "[$statusComputerName] $statusMessage"
                return [PSCustomObject]@{
                    ComputerName      = $statusComputerName
                    OverallStatus     = "Failed"
                    QualysUninstalled = $statusQualysUninstalled
                    QualysInstalled   = $statusQualysInstalled
                    Message           = $statusMessage
                }
            }
            $statusMessage = "Existing Qualys agent uninstalled successfully."
        } else {
            Write-Verbose "[$statusComputerName] No existing Qualys installation found to remove."
            $statusQualysUninstalled = $null # Explicitly $null as no uninstall attempt was made
            $statusMessage = "No existing Qualys agent found."
        }

        # Proceed with installation
        $installedResult = Install-QualysAgent -PassedConfig $CurrentConfig
        $statusQualysInstalled = $installedResult
        if (-not $installedResult) {
            $statusMessage += " Qualys Agent new installation failed." # Append to existing message
            Write-Error "[$statusComputerName] Qualys Agent installation failed."
             return [PSCustomObject]@{
                ComputerName      = $statusComputerName
                OverallStatus     = "Failed"
                QualysUninstalled = $statusQualysUninstalled
                QualysInstalled   = $statusQualysInstalled
                Message           = $statusMessage.Trim()
            }
        } else {
            $statusMessage += " Qualys Agent new installation succeeded."
        }

        $statusOverall = "Success"
        Write-Verbose "[$statusComputerName] Qualys Agent processing completed successfully on this server."
        
    } catch {
        # Catch any unexpected error within the ScriptBlock
        $statusOverall = "Failed"
        $statusMessage = "An unexpected error occurred: $($_.Exception.Message)"
        Write-Error "[$statusComputerName] $statusMessage"
        # $statusQualysUninstalled and $statusQualysInstalled will retain their last set values
    }

    # Construct and return the status object
    return [PSCustomObject]@{
        ComputerName      = $statusComputerName
        OverallStatus     = $statusOverall
        QualysUninstalled = $statusQualysUninstalled
        QualysInstalled   = $statusQualysInstalled
        Message           = $statusMessage.Trim()
    }

} -ThrottleLimit $ThrottleLimit

# --- Summary Reporting ---
if ($results) {
    Write-Host "`n--- Qualys Agent Deployment Summary Report ---" -ForegroundColor Cyan
    
    $successfulServers = $results | Where-Object {$_.OverallStatus -eq "Success"}
    $failedServers = $results | Where-Object {$_.OverallStatus -ne "Success"} # Includes those that might not have PSComputerName if Invoke-Command failed early for them

    if ($successfulServers) {
        Write-Host "`nSuccessful Servers ($($successfulServers.Count)):" -ForegroundColor Green
        $successfulServers | ForEach-Object {
            Write-Host "- $($_.ComputerName): $($_.Message)" 
            Write-Host "  Qualys Uninstalled: $($_.QualysUninstalled), Qualys Installed: $($_.QualysInstalled)"
        }
    }

    if ($failedServers) {
        Write-Host "`nFailed Servers ($($failedServers.Count)):" -ForegroundColor Red
        $failedServers | ForEach-Object {
            $serverIdentifier = if ($_.PSComputerName) { $_.PSComputerName } else { $_.ComputerName } # Use PSComputerName if available, else our ComputerName
            Write-Host "- $serverIdentifier : $($_.Message)" -ForegroundColor Red
            Write-Host "  Qualys Uninstalled: $($_.QualysUninstalled), Qualys Installed: $($_.QualysInstalled)"
        }
    }

    # Handle cases where Invoke-Command might have had issues for some servers not returning our custom object
    $allAttemptedServers = $servers # From the input list
    $reportedServers = $results | Select-Object -ExpandProperty PSComputerName -ErrorAction SilentlyContinue # Get names from Invoke-Command output
    if($reportedServers -is [string]){ $reportedServers = @($reportedServers)} # Ensure it's an array if only one server reported

    $unreachableOrNonReportingServers = $allAttemptedServers | Where-Object { $_ -notin $reportedServers }
    if ($unreachableOrNonReportingServers.Count -gt 0) {
        Write-Host "\nServers Attempted but Did Not Report Status ($($unreachableOrNonReportingServers.Count)):" -ForegroundColor Yellow
        $unreachableOrNonReportingServers | ForEach-Object { Write-Host "- $_ (May have been unreachable or failed before status reporting)" }
    }

    Write-Host "`n------------------------------------------" -ForegroundColor Cyan
} else {
    Write-Warning "No results received from Invoke-Command. Check connectivity to servers or other script errors."
}


if ($Global:IsTranscribing) {
    Stop-Transcript
}