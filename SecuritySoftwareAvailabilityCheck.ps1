
<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

For PHYSICAL Servers
This Script will  Check if Splunk, Nessus Agent and CrowStrike is Installed on the Server or not, it will also pull out the Version details of those software. for the list of server saved on the servers.txt file
The script run on a persistance PSsession and clears the session when done.
#>

function InstallChecker {  
    $reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
    $sessions = $reachableServers | New-PSSession   
    $result = @()
    ForEach ($sec in $sessions) {   
     
        
        $result += Invoke-Command -Session $sec -ScriptBlock {


            $hostname = (Get-ComputerInfo -Property CsName).CsName

            Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
            Where-Object { $_.DisplayName -match "Universal*|CrowdStrike*|Nessus*" } | 
            Select-Object @{Name = "DisplayName"; Expression = { $_.DisplayName } },
            @{Name = "DisplayVersion"; Expression = { $_.DisplayVersion } },
            @{Name = "InstallDate"; Expression = { $_.InstallDate } },
            @{Name = "ServerName"; Expression = { $hostname } }
         
          
          
        }      
        
    }

     
     
    $result | ft -AutoSize | Out-File -FilePath ".\InstalledSoftware.txt" -Force
    Get-PSSession | Disconnect-PSSession | Remove-PSSession
}  
InstallChecker