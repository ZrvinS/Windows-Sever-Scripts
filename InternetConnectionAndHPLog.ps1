

<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will Check if a server can Access internet or not also if HPE Log Uploading Site is accessible or not: Status Code 200: means it's Accessible, Nothing means, server cannot access site
for the list of server saved on the servers.txt file
The script run on a persistance PSsession and clears the session when done.
#>

$serverssession = Get-Content(".\servers.txt") | Test-NetConnection | Where-Object { $_.PingSucceeded -eq $true } 
$session = $serverssession | New-PSSession

$result = foreach ($sec in $session) {

    Invoke-Command -Session $sec -ScriptBlock {

  
        hostname
        $netconnection = Invoke-WebRequest "www.google.com" -UseBasicParsing
        $hplogsite = Invoke-WebRequest "https://hprc-h2.it.hpe.com/hprc/" -UseBasicParsing 
        Write-Output "Internet Connection Status Code: $($netconnection.StatusCode)"
        Write-Output "Hp Log Site connection Status Code: $($hplogsite.StatusCode)"  
   
    }
    
    Disconnect-PSSession -Session $sec | Remove-PSSession    
}

$result |  Out-File -FilePath "./connectionoutput.txt" -Force
