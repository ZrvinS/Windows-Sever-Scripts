$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession  

$result = @()
foreach($sec in $sessions){
   
   
    $result += Invoke-Command -Session $sec -ScriptBlock {
             
        xpfinfo -i
        Write-Output "`r`n"
    } 
   
   
  
}

$result| Out-File -FilePath ".\ldev.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession