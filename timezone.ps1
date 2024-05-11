
<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

For PHYSICAL Servers
This Script will retrieve Time Zone dtails for the list of server saved on the servers.txt file
The script run on a persistance PSsession and clears the session when done.
#>

$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession   
$result = @()
foreach($sec in $sessions){
  
  
   $result += Invoke-Command -Session $sec -ScriptBlock {
             
        Get-WmiObject Win32_TimeZone
        
   } 
  
  
 
}

$result | select PSComputerName, Caption| ft -AutoSize | Out-File -FilePath ".\TimezoneResult.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession 


$array = New-Object -TypeName System.Collections.ArrayList

$array.Add("adfai")