
$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 

$result = @()
$result = foreach($server in $reachableServers.ComputerName){   
            
    Get-WmiObject win32_PnpSignedDriver -ComputerName $server | ?{$_.DeviceName -match "HPE S*"} | Select-Object __SERVER, Description, DriverVersion
    Get-WmiObject win32_PnpSignedDriver -ComputerName $server | ?{$_.DeviceName -match "QLOGIC*"} | Select-Object __SERVER, Description, DriverVersion 


}

$result| Out-File -FilePath ".\HBAResult.txt" -Force
