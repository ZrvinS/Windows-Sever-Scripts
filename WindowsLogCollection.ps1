# Define the output folder for logs
$outputFolder = "\\g7w10002s\E$\RemoteLogCollection\LogsBackup"

# Create the output folder if it doesn't exist
if (!(Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder
}

# Copy CBS logs (Component-Based Servicing logs)
$cbsLogPath = "C:\Windows\Logs\CBS\CBS.log"
if (Test-Path -Path $cbsLogPath) {
    Copy-Item -Path $cbsLogPath -Destination $outputFolder -Force
}

# Copy Memory Dumps (if they exist)
$memoryDumpPath = "C:\Windows\Memory.dmp"
if (Test-Path -Path $memoryDumpPath) {
    Copy-Item -Path $memoryDumpPath -Destination $outputFolder -Force
}

# Gather Windows Event Logs (Application, System, Security, etc.)
$eventLogs = @("Application", "System", "Security")
foreach ($logName in $eventLogs) {
    $logFile = Join-Path -Path $outputFolder -ChildPath "$logName.evtx"
    wevtutil epl $logName $logFile
}

# Copy Windows Update Logs
$windowsUpdateLogPath = "C:\Windows\WindowsUpdate.log"
if (Test-Path -Path $windowsUpdateLogPath) {
    Copy-Item -Path $windowsUpdateLogPath -Destination $outputFolder -Force
}

# Copy Setup Logs
$setupLogsPath = "C:\Windows\Panther"
if (Test-Path -Path $setupLogsPath) {
    Copy-Item -Path $setupLogsPath -Destination $outputFolder -Recurse -Force
}

# Copy System Info (System and Network Configuration)
$systemInfoFile = Join-Path -Path $outputFolder -ChildPath "SystemInfo.txt"
systeminfo | Out-File -FilePath $systemInfoFile

# Export System and Application Event Logs to text files for easier viewing
$systemEventText = Join-Path -Path $outputFolder -ChildPath "SystemEventLog.txt"
Get-EventLog -LogName System | Out-File -FilePath $systemEventText

$applicationEventText = Join-Path -Path $outputFolder -ChildPath "ApplicationEventLog.txt"
Get-EventLog -LogName Application | Out-File -FilePath $applicationEventText

Write-Output "Log collection complete. Logs are saved in $outputFolder"
