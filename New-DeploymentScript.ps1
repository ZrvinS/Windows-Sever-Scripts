<#
.SYNOPSIS
    Deploys code to a list of servers and retrieves results.

.DESCRIPTION
    This script provides a wireframe for deploying code to multiple servers.
    It includes parameter handling, error management, logging, secure credential usage,
    and parallel execution capabilities for improved performance.

.PARAMETER ServerListPath
    Path to a text file containing a list of server names, one per line.
    If not provided, ServerNames parameter must be used.

.PARAMETER ServerNames
    An array of server names to target for deployment.
    If not provided, ServerListPath parameter must be used.

.PARAMETER Credential
    Specifies a user account that has permission to perform this action.
    The default is the current user.

.PARAMETER DeploymentPackagePath
    Path to the code or package to be deployed. (This is a placeholder and should be adapted)

.PARAMETER LogFilePath
    Path to the log file. Defaults to ".\DeploymentLog.txt".

.EXAMPLE
    .\New-DeploymentScript.ps1 -ServerListPath "C:\temp\servers.txt" -Credential (Get-Credential) -DeploymentPackagePath "C:\packages\mycode.zip"

.EXAMPLE
    .\New-DeploymentScript.ps1 -ServerNames "server1", "server2" -Credential (Get-Credential) -DeploymentPackagePath "C:\packages\mycode.zip" -LogFilePath "C:\logs\deploy.log"

.NOTES
    Author: Jules
    Date: $(Get-Date -Format 'yyyy-MM-dd')
    Requires PowerShell 5.1 or higher. For parallel execution, PowerShell 7+ is recommended.
#>
[CmdletBinding(DefaultParameterSetName = 'FilePath')]
param (
    [Parameter(Mandatory = $false, ParameterSetName = 'FilePath', HelpMessage = "Path to a text file containing a list of server names, one per line.")]
    [string]$ServerListPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName', HelpMessage = "An array of server names to target for deployment.")]
    [string[]]$ServerNames,

    [Parameter(Mandatory = $true, HelpMessage = "Specifies a user account that has permission to perform this action.")]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $true, HelpMessage = "Path to the code or package to be deployed.")]
    [string]$DeploymentPackagePath,

    [Parameter(HelpMessage = "Path to the log file. Defaults to '.\DeploymentLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt'.")]
    [string]$LogFilePath = ".\DeploymentLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

#region Setup and Initialization
Function Write-Log {
    param (
        [string]$Message,
        [switch]$ErrorLog
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    if ($ErrorLog) {
        $LogEntry = "$Timestamp - ERROR - $Message"
        Write-Error $Message # Also write to error stream
    }
    Add-Content -Path $LogFilePath -Value $LogEntry
    Write-Host $LogEntry
}

Write-Log "Script execution started."

# Validate parameters
if ($PSCmdlet.ParameterSetName -eq 'FilePath') {
    if (-not (Test-Path $ServerListPath)) {
        Write-Log "Error: Server list file '$ServerListPath' not found." -ErrorLog
        exit 1
    }
    try {
        $ResolvedServerNames = Get-Content $ServerListPath -ErrorAction Stop
        Write-Log "Successfully read server list from '$ServerListPath'."
    }
    catch {
        Write-Log "Error reading server list file '$ServerListPath': $($_.Exception.Message)" -ErrorLog
        exit 1
    }
}
elseif ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
    if ($null -eq $ServerNames -or $ServerNames.Count -eq 0) {
        Write-Log "Error: No server names provided via ServerNames parameter." -ErrorLog
        exit 1
    }
    $ResolvedServerNames = $ServerNames
    Write-Log "Using server names provided via ServerNames parameter."
}
else {
    Write-Log "Error: Invalid parameter set. Please provide either ServerListPath or ServerNames." -ErrorLog
    exit 1 # Should not happen with CmdletBinding but good for safety
}

if (-not (Test-Path $DeploymentPackagePath)) {
    Write-Log "Error: Deployment package '$DeploymentPackagePath' not found." -ErrorLog
    exit 1
}

Write-Log "Target servers: $($ResolvedServerNames -join ', ')"
Write-Log "Deployment package: $DeploymentPackagePath"
Write-Log "Credentials provided for user: $($Credential.UserName)"
#endregion Setup and Initialization

#region Main Processing Logic
$results = @()

# Determine if parallel processing can be used
$useParallel = $PSVersionTable.PSVersion.Major -ge 7

if ($useParallel) {
    Write-Log "PowerShell 7+ detected. Using ForEach-Object -Parallel for faster execution."
    $workflow = {
        param($TargetServer, $Credential, $DeploymentPackagePath, $LogFilePath_Thread)

        # Thread-safe logging (optional, simple approach shown)
        Function Write-ThreadLog {
            param ([string]$Message)
            $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $LogEntry = "$Timestamp - [$TargetServer] - $Message"
            Add-Content -Path $LogFilePath_Thread -Value $LogEntry # Each thread could log to its own temp or use a synchronized method
            Write-Host $LogEntry
        }

        Write-ThreadLog "Starting deployment to $TargetServer."
        $session = $null
        $result = [PSCustomObject]@{
            Server = $TargetServer
            Success = $false
            Details = ""
            Output = $null
        }

        try {
            # Establish a remote session (optional, useful if multiple commands are run)
            # $session = New-PSSession -ComputerName $TargetServer -Credential $Credential -ErrorAction Stop
            # Write-ThreadLog "Session created for $TargetServer."

            # Example: Copy deployment package (adapt this to your needs)
            # This is a placeholder. You'll need to implement robust file transfer.
            # For simple cases, Invoke-Command can copy small files via script block,
            # but for larger packages, consider Copy-Item with a session or Robocopy.
            Write-ThreadLog "Attempting to copy deployment package to $TargetServer (placeholder action)."
            # Invoke-Command -Session $session -ScriptBlock {
            #     param($Path)
            #     # Example: New-Item -ItemType Directory -Path "C:\temp\deployment" -Force
            #     # Copy-Item -Path $Path -Destination "C:\temp\deployment" -Force -Recurse # This would require the source path to be accessible from the remote machine or use PSSession for copying
            # } -ArgumentList $DeploymentPackagePath -ErrorAction Stop

            # --- Deployment Logic ---
            # This is where your main deployment commands will go.
            # Use Invoke-Command to run scripts or commands on the remote server.
            Write-ThreadLog "Executing deployment script on $TargetServer."
            $deploymentOutput = Invoke-Command -ComputerName $TargetServer -Credential $Credential -ScriptBlock {
                param($PackagePath)

                # Example remote actions:
                # 1. Extract package
                # Write-Host "Extracting $PackagePath on $using:TargetServer..."
                # Expand-Archive -Path $PackagePath -DestinationPath "C:\staging" -Force

                # 2. Run installer or script
                # Write-Host "Running installation script on $using:TargetServer..."
                # $installResult = Start-Process -FilePath "C:\staging\install.ps1" -Wait -PassThru
                # if ($installResult.ExitCode -ne 0) {
                #     throw "Installation script failed with exit code $($installResult.ExitCode)"
                # }

                # 3. Perform checks
                # Write-Host "Performing post-deployment checks on $using:TargetServer..."

                # Placeholder for actual deployment logic
                Write-Host "Deployment package path received: $PackagePath"
                Write-Host "Simulating deployment actions on $($using:env:COMPUTERNAME)..."
                Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5) # Simulate work
                
                return "Deployment simulated successfully on $($using:env:COMPUTERNAME) at $(Get-Date)."
            } -ArgumentList $DeploymentPackagePath -ErrorAction Stop # Use -Session $session if session is created

            $result.Success = $true
            $result.Details = "Deployment successful."
            $result.Output = $deploymentOutput
            Write-ThreadLog "Deployment to $TargetServer completed successfully."
        }
        catch {
            $result.Details = "Error during deployment to $TargetServer: $($_.Exception.Message)"
            Write-ThreadLog "Error during deployment to $TargetServer: $($_.Exception.Message)"
        }
        finally {
            # if ($session) {
            #     Write-ThreadLog "Removing session for $TargetServer."
            #     Remove-PSSession $session
            # }
        }
        return $result
    }
    $results = $ResolvedServerNames | ForEach-Object -Parallel $workflow -ThrottleLimit 5 -ArgumentList $Credential, $DeploymentPackagePath, $LogFilePath # Adjust ThrottleLimit as needed
}
else {
    Write-Log "PowerShell version less than 7. Using sequential ForEach-Object loop."
    foreach ($server in $ResolvedServerNames) {
        Write-Log "Starting deployment to $server."
        $session = $null
        $result = [PSCustomObject]@{
            Server = $server
            Success = $false
            Details = ""
            Output = $null
        }

        try {
            # Establish a remote session (optional, useful if multiple commands are run)
            # $session = New-PSSession -ComputerName $server -Credential $Credential -ErrorAction Stop
            # Write-Log "Session created for $server."

            # --- Deployment Logic ---
            Write-Log "Executing deployment script on $server."
             $deploymentOutput = Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
                param($PackagePath)
                Write-Host "Deployment package path received: $PackagePath"
                Write-Host "Simulating deployment actions on $($using:env:COMPUTERNAME)..."
                Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5) # Simulate work
                return "Deployment simulated successfully on $($using:env:COMPUTERNAME) at $(Get-Date)."
            } -ArgumentList $DeploymentPackagePath -ErrorAction Stop # Use -Session $session if session is created

            $result.Success = $true
            $result.Details = "Deployment successful."
            $result.Output = $deploymentOutput
            Write-Log "Deployment to $server completed successfully."
        }
        catch {
            $errorMessage = "Error during deployment to $server: $($_.Exception.Message)"
            if ($_.Exception.InnerException) {
                $errorMessage += " Inner Exception: $($_.Exception.InnerException.Message)"
            }
            $result.Details = $errorMessage
            Write-Log $errorMessage -ErrorLog
        }
        finally {
            # if ($session) {
            #     Write-Log "Removing session for $server."
            #     Remove-PSSession $session
            # }
        }
        $results += $result
    }
}
#endregion Main Processing Logic

#region Results Summary and Cleanup
Write-Log "Deployment processing complete. Summarizing results."

$successfulDeployments = $results | Where-Object { $_.Success }
$failedDeployments = $results | Where-Object { -not $_.Success }

Write-Log "--- Deployment Summary ---"
Write-Log "Total servers processed: $($results.Count)"
Write-Log "Successful deployments: $($successfulDeployments.Count)"
Write-Log "Failed deployments: $($failedDeployments.Count)"

if ($successfulDeployments.Count -gt 0) {
    Write-Log "Successfully deployed to:"
    $successfulDeployments | ForEach-Object { Write-Log "  - $($_.Server)" }
}

if ($failedDeployments.Count -gt 0) {
    Write-Log "Failed deployments on:"
    $failedDeployments | ForEach-Object { Write-Log "  - $($_.Server): $($_.Details)" }
}

# Example of accessing output from a specific server (if needed)
# $server1Output = ($results | Where-Object {$_.Server -eq "server1"}).Output
# if ($server1Output) {
#   Write-Log "Output from server1: $server1Output"
# }

Write-Log "Script execution finished. Log file located at: $LogFilePath"
#endregion Results Summary and Cleanup
