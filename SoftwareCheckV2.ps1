<#
Contact (if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

For PHYSICAL Servers
This script will check if Splunk, Nessus Agent, and CrowdStrike are installed on the server or not, and it will also pull out the version details of those software. For the list of servers saved in the servers.txt file, the script runs on a persistent PS session and clears the session when done.
#>

function InstallChecker {
    $serverList = Get-Content -Path "./servers.txt"
    $reachableServers = @()
    $unreachableServers = @()
    $results = @()
    $softwareList = @("Universal*", "Nessus Agent", "CrowdStrike", "HP Agent", "Opsware")

    foreach ($server in $serverList) {
        $connection = Test-Connection -ComputerName $server -Count 1 -Quiet
        if ($connection) {
            $reachableServers += $server
        }
        else {
            $unreachableServers += $server
            Write-Output "$server is not reachable."
        }
    }

    $sessions = New-PSSession -ComputerName $reachableServers

    foreach ($session in $sessions) {
        $results += Invoke-Command -Session $session -ScriptBlock {
            param($softwareList)
            $hostname = (Get-ComputerInfo -Property CsName).CsName
            $softwareResults = @()

            foreach ($software in $using:softwareList) {
                $installedSoftware = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                Where-Object { $_.DisplayName -match $software } |
                Select-Object DisplayName, DisplayVersion, InstallDate

                if ($installedSoftware.Count -eq 0) {
                    $softwareResults += [PSCustomObject]@{
                        ServerName     = $hostname
                        DisplayName    = "$software not installed"
                        DisplayVersion = "N/A"
                        InstallDate    = "N/A"
                    }
                }
                else {
                    $installedSoftware | ForEach-Object {
                        $softwareResults += [PSCustomObject]@{
                            ServerName     = $hostname
                            DisplayName    = $_.DisplayName
                            DisplayVersion = $_.DisplayVersion
                            InstallDate    = $_.InstallDate
                        }
                    }
                }
            }

            return $softwareResults
        } -ErrorAction SilentlyContinue
    }

    if ($results) {
        $results | Format-Table -AutoSize | Out-File -FilePath ".\InstalledSoftware.txt" -Force
        Write-Output "Results saved to InstalledSoftware.txt"
    }
    else {
        Write-Output "No results to save."
    }

    if ($unreachableServers) {
        $unreachableServers | ForEach-Object {
            [PSCustomObject]@{
                ServerName     = $_
                DisplayName    = "Server not reachable"
                DisplayVersion = "N/A"
                InstallDate    = "N/A"
            }
        } | Format-Table -AutoSize | Out-File -FilePath ".\UnreachableServers.txt" -Force
        Write-Output "Unreachable servers logged in UnreachableServers.txt"
    }

    # Cleanup sessions
    $sessions | ForEach-Object {
        Disconnect-PSSession -Session $_
        Remove-PSSession -Session $_
    }
}

InstallChecker
