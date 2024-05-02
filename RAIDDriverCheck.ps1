<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will check if number or HP Logical DISK on the list of server saved on the servers.txt file
Which will help you determin if the RAID is configured properly or not
#>

$serverconnectTest =  Get-Content(".\servers.txt") | Test-NetConnection | Where-Object {$_.PingSucceeded -eq $true}
$result = @()
$result = foreach($server in $serverconnectTest.ComputerName){

    $out = Get-WmiObject -Class Win32_PnPSignedDriver -ComputerName $server | ?{$_.FriendlyName -like "HP*LOGICAL*SCSI*"} |select __SERVER, FriendlyName, Description
    $out | Group-Object __SERVER
}

$result | Out-File ".\RAID.txt" -Force 

