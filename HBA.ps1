<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will HBA Driver and Version for the list of server saved on the servers.txt file

#>

$Servers = Get-Content "servers.txt" 


$result =  foreach($ser in $servers){

 Get-WmiObject win32_PnpSignedDriver -ComputerName $ser | ?{$_.DeviceName -match "HP FlexFabric 10Gb 2-port 554M Adapter"} | Select-Object __SERVER, DriverProviderName,FriendlyName, DriverVersion -First 1
 Get-WmiObject win32_PnpSignedDriver -ComputerName $ser | ?{$_.DeviceName -match "HP FlexFabric 10Gb 2-port 554FLB Adapter"} | Select-Object __SERVER, DriverProviderName,FriendlyName, DriverVersion -First 1

}


$result | Out-File -FilePath ".\HBAResult.txt" 