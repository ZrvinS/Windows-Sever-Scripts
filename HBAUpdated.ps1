
<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will Retrive the HBA Drive With Storage Drivers for the list of server saved on the servers.txt file

#>


$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 

$result = @()
$result = foreach ($server in $reachableServers.ComputerName) {   
            
    Get-WmiObject win32_PnpSignedDriver -ComputerName $server | ? { $_.DeviceName -match "HPE S*" } | Select-Object __SERVER, DriverProviderName, Description, DriverVersion
    Get-WmiObject win32_PnpSignedDriver -ComputerName $server | ? { $_.DeviceName -match "QLOGIC*" } | Select-Object __SERVER, DriverProviderName, Description, DriverVersion 
    Get-WmiObject win32_PnpSignedDriver -ComputerName $server | ? { $_.DeviceName -match "HP FlexFabric*" } | Select-Object __SERVER, DriverProviderName, Description, DriverVersion -First 1
    Get-WmiObject win32_PnpSignedDriver -ComputerName $server | ? { $_.DeviceName -match "Emulex*" } | Select-Object __SERVER, DriverProviderName, FriendlyName, Description, DriverVersion -First 1
}

$result | Out-File -FilePath ".\HBAResult.txt" -Force
