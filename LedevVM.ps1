<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

For VIRTUAL Servers
This Script will retrieve LDEV ID  and Drive Letter With Drive Number details for the list of server saved on the servers.txt file
The script run on a persistance PSsession and clears the session when done.
#>

$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession  

$result = @()
foreach ($sec in $sessions) {
   
   
    $result += Invoke-Command -Session $sec -ScriptBlock {
        
        Get-WmiObject -Class Win32_OperatingSystem | select Caption 
        xpinfo -i
        
        $Letter = Get-Volume | select -ExpandProperty DriveLetter
        foreach ($let in $Letter) {

            $dsk = Get-Volume | where DriveLetter -eq $let | Get-Partition | Get-Disk
            Write-Output "Disk: $($dsk.Number):$let"
        }

        Write-Output "`r`n"
    } 
   
   
  
}

$result | Out-File -FilePath ".\ldevVM.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession