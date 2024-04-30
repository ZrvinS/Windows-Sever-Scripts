
$reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
$sessions = $reachableServers | New-PSSession  

$result = @()
foreach($server in $sessions){

        Invoke-Command -SessionName $server -ScriptBlock{
            
         
            Get-WmiObject win32_PnpSignedDriver | ?{$_.DeviceName -match "HP FlexFabric 10Gb 2-port 554M Adapter"} | Select-Object __SERVER, DriverProviderName,FriendlyName, DriverVersion -First 1
            Get-WmiObject win32_PnpSignedDriver | ?{$_.DeviceName -match "HP FlexFabric 10Gb 2-port 554FLB Adapter"} | Select-Object __SERVER, DriverProviderName,FriendlyName, DriverVersion -First 1
        }
}

$result| Out-File -FilePath ".\HBAResult.txt" -Force
Get-PSSession | Disconnect-PSSession | Remove-PSSession