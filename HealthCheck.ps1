<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will Perform a Health Check of the Server List provided. 
It will Output 3 Different Files
    1.  Automatic Stopped Services and CPU utilization in Percentage
    2.  2 Process Consuming Highest Memory
    3.  C Drive Disk Free Size and Total Size

#>

$server = Get-Content("./servers.txt") | Test-NetConnection | Where-Object { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 

$result = @()
$Memory = @()
$diskSpace = @()
foreach($ser in $server.ComputerName){

 $result += Get-WmiObject Win32_Service -ComputerName $ser `
                        | Where-Object{$_.StartMode -match "Auto" -and $_.State -match "Stopped"} `
                        | Select-Object __SERVER, Name, State, StartMode
 
 $result +=  "Current CPU Utilization in Percent "+ (Get-WmiObject -Class Win32_Processor -ComputerName $ser `
                        | Measure-Object -Property LoadPercentage -Average).Average +"`r`n"

 $Memory += Get-WmiObject -Class Win32_Process -ComputerName $ser `
                                               | Sort-Object WS -Descending `
                                               | Select-Object __SERVER, Name, `
                                                 @{n="Memory/MB"; e={[math]::Round($_.WS/1MB,2)}} -First 2 
 $Memory+= "`r`n"
 $diskSpace += Get-WmiObject Win32_logicaldisk | Where-Object {$_.DeviceID -match "C:"} `
                                               | Select-Object __SERVER, DeviceID, `
                                                 @{n="FreeSpace"; e={[math]::Round($_.FreeSpace/1GB,2)}}, `
                                                 @{n="TotalCapacity";e={[math]::Round($_.Size/1GB,2)}}
 
}

$result | Out-File -FilePath ".\ServicesCPU_HealthCheck.txt" -Force
$Memory | Out-File -FilePath ".\Memory_HealthCheck.txt" -Force
$diskSpace | Out-File -FilePath ".\Disk_HealthCheck.txt" -Force


