
<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

For PHYSICAL Servers
This Script will retrieve LDEV ID dtails for the list of server saved on the servers.txt file
The script run on a persistance PSsession and clears the session when done.
#>

$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | Where-Object { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession   
$result = @()
foreach ($sec in $sessions) {
  
  
    $result += Invoke-Command -Session $sec -ScriptBlock {
             
        $portresult = Get-InitiatorPort   
        $portresult | Select-Object InstanceName, PortAddress, PSComputerName -Exclude PSShowComputerName, RunspaceId 
         
              

        Write-Output "`r`n"
    } 
  
  
 
}

$result | Select-Object * -ExcludeProperty RunspaceId | Format-Table -AutoSize | Out-File -FilePath ".\ldev.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession