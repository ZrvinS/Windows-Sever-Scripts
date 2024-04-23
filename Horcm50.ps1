<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will automatically check for Horcm50 Service and starts the service 
if the service is stopped

The script run on a persistance PSsession and clears the session when done.
#>
function ServiceMonitor {

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string]
        $serverName
    )
    begin {

        $reachableServers = Get-Content("./servers.txt") | Test-NetConnection | Where-Object { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
        $sessions = $reachableServers | New-PSSession
        # New-EventLog -LogName "ServiceMonitoring" -Source "ServiceError" -ErrorAction Ignore
    }
    
    process {

        foreach ($session in $sessions) {        
            Invoke-Command -Session $session -ScriptBlock {
                
                $servieName = "horcm50"          
             
                $servicestatus = Get-Service -Name $servieName | Select-Object DisplayName, Status, PsComputerName, Name -ErrorAction SilentlyContinue -ErrorVariable err
                 if($null -eq $servicestatus){
                    
                    Write-Output "Service is not present"
                    # Write-EventLog -LogName ServiceMonitoring -Source "ServiceError" -EntryType Error -EventId 404 -Message "Horcm50Service Not Present in the Server"

                 }elseif($servicestatus.Status -eq "Stopped"){
                    # try {
                        Start-Service $servicestatus.Name -ErrorAction Stop
                    # }
                    # catch {
                    #     Write-EventLog -LogName ServiceMonitoring -Source "ServiceError" -EntryType Error -EventId 500 -Message "Service Failed to Start"

                    # }
                   
                    Write-Output "Service is $($servicestatus.Status)
                 }else{
                     Write-Output "Service is $($servicestatus.Status)
                   }
                                    
            }
         
        }
    }
    
    end {
    
        Get-PSSession | Disconnect-PSSession | Remove-PSSession
        
    }
}
ServiceMonitor