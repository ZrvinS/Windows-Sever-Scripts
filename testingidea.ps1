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

# Loop through each server
foreach ($server in $servers) {
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
            
            # Invoke command to get installed software
            $software = Invoke-Command -Session $session -ScriptBlock {
                Get-WmiObject -Class Win32_Product | Select-Object Name, Version
            } -ErrorAction Stop

            # Add software information to result
            $result.Software = $software | Select-Object Name, Version

            # Close PSSession
            Remove-PSSession $session
        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
            $result.Status = "Connection Failed (WinRM)"
            $failedWinRM += $server
        }
        catch [System.Runtime.InteropServices.COMException] {
            $result.Status = "Connection Failed (RPC)"
            $failedRPC += $server
        }
        catch {
            $result.Status = "Connection Failed (Unknown)"
        }
    }
    
    # Add result to results array
    $results += $result
}

# Export results to CSV
$results | Export-Csv -Path "C:\path\to\results.csv" -NoTypeInformation

# Log servers that are not reachable or connection failed
$results | Where-Object { $_.Status -ne "Reachable" } | Select-Object ServerName, Status | Export-Csv -Path "C:\path\to\connection_issues.csv" -NoTypeInformation

# Log servers that failed with WinRM
$failedWinRM | Out-File -FilePath "C:\path\to\failed_winrm.txt"

# Log servers that failed with RPC
$failedRPC | Out-File -FilePath "C:\path\to\failed_rpc.txt"