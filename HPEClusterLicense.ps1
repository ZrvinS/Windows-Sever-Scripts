<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

For PHY Cluster Servers
This Script will retrieve HPE CX License status for the list of server saved on the servers.txt file
The script run on a persistance PSsession and clears the session when done.
#>

$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession  

$result = @()
foreach($sec in $sessions){
   
   
    $result += Invoke-Command -Session $sec -ScriptBlock {
        
        $license = pairdisplay -g BCDR_CA01 -I50 -CLI -fcx
        $match = [regex]::Matches($license, '\b\d{6}\b') | Select-Object -Unique
        $match | select PSComputerName, Value
        Write-Output "`r`n"
    } 
   
   
  
}

$result| Out-File -FilePath ".\LicenseStatus.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession