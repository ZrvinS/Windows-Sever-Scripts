$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession   
$result = @()
foreach($sec in $sessions){
  
  
   $result += Invoke-Command -Session $sec -ScriptBlock {
             
       $portresult = Get-InitiatorPort   
       $portresult | select InstanceName,PortAddress,PSComputerName -Exclude PSShowComputerName, RunspaceId 
         
              

       Write-Output "`r`n"
   } 
  
  
 
}

$result | select * -ExcludeProperty RunspaceId | ft -AutoSize | Out-File -FilePath ".\ldev.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession