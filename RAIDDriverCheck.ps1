$serverconnectTest =  Get-Content(".\servers.txt") | Test-NetConnection | Where-Object {$_.PingSucceeded -eq $true}
$result = @()
$result = foreach($server in $serverconnectTest.ComputerName){

    $out = Get-WmiObject -Class Win32_PnPSignedDriver -ComputerName $server | ?{$_.FriendlyName -like "HP*LOGICAL*SCSI*"} |select __SERVER, FriendlyName, Description
    $out | Group-Object __SERVER
}

$result | Out-File ".\RAID.txt" -Force 

