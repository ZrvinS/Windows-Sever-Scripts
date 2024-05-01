$serverconnectTest =  Get-Content(".\servers.txt") | Test-NetConnection | Where-Object {$_.PingSucceeded -eq $true}
$result = @()
$result = foreach($server in $serverconnectTest.ComputerName){

Get-WmiObject -Class Win32_PnPSignedDriver -ComputerName $server | ?{$_.FriendlyName -match "H*LOGICAL*"} |select __SERVER, FriendlyName, Description

}

$result | Out-File ".\RAID.txt" -Force 

