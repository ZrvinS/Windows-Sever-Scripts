# Read applications from XML file
$xmlFile = "C:\path\to\applications.xml"
$applications = @()
if (Test-Path $xmlFile) {
    $xmlData = [xml](Get-Content $xmlFile)
    $applications = $xmlData.Applications.Application
}

# List of server names
$servers = Get-Content -Path "C:\path\to\server_list.txt"
$results = @()
$failedWinRM = @()
$failedRPC = @()

# Function to test network connection
function Test-NetworkConnection {
    param (
        [string]$ComputerName
    )
    $pingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
    return $pingResult
}

# Function to collect results from job
function Collect-Results {
    param (
        [System.Management.Automation.PSJob[]]$Jobs
    )
    $allResults = @()
    foreach ($job in $Jobs) {
        $allResults += Receive-Job -Job $job
        Remove-Job -Job $job
    }
    return $allResults
}

# Loop through each server and create job for each server
$jobs = @()
foreach ($server in $servers) {
    $job = Start-Job -ScriptBlock {
        param($server, $applications)
        
        # Test network connection
        $connectionTest = Test-NetworkConnection -ComputerName $server
        $result = [PSCustomObject]@{
            ServerName = $server
            Status = if ($connectionTest) { "Reachable" } else { "Not Reachable" }
        }

        if ($connectionTest) {
            # Attempt to create PSSession
            try {
                $session = New-PSSession -ComputerName $server -ErrorAction Stop
                
                # Invoke command to get installed software for each application
                $applicationResults = @()
                foreach ($app in $applications) {
                    $applicationResult = Invoke-Command -Session $session -ScriptBlock {
                        param($appName)
                        Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$appName*" } | Select-Object Name, Version
                    } -ArgumentList $app -ErrorAction SilentlyContinue
                    if ($applicationResult) {
                        $applicationResults += $applicationResult
                    }
                }

                # Add application results to result
                $result.ApplicationResults = $applicationResults

                # Close PSSession
                Remove-PSSession $session
            }
            catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
                $result.Status = "Connection Failed (WinRM)"
            }
            catch [System.Runtime.InteropServices.COMException] {
                $result.Status = "Connection Failed (RPC)"
            }
            catch {
                $result.Status = "Connection Failed (Unknown)"
            }
        }

        return $result
    } -ArgumentList $server, $applications
    $jobs += $job
}

# Wait for all jobs to finish and collect results
$results = Collect-Results -Jobs $jobs

# Export results to CSV
$results | Export-Csv -Path "C:\path\to\results.csv" -NoTypeInformation

# Log servers that are not reachable or connection failed
$results | Where-Object { $_.Status -ne "Reachable" } | Select-Object ServerName, Status | Export-Csv -Path "C:\path\to\connection_issues.csv" -NoTypeInformation

# Log servers that failed with WinRM
$failedWinRM = $results | Where-Object { $_.Status -eq "Connection Failed (WinRM)" } | Select-Object -ExpandProperty ServerName
$failedWinRM | Out-File -FilePath "C:\path\to\failed_winrm.txt"

# Log servers that failed with RPC
$failedRPC = $results | Where-Object { $_.Status -eq "Connection Failed (RPC)" } | Select-Object -ExpandProperty ServerName
$failedRPC | Out-File -FilePath "C:\path\to\failed_rpc.txt"