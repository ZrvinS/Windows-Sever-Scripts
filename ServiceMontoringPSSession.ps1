function ServiceMonitor {

    [CmdletBinding()]
    param (
        
    )
    begin {

        $reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
        $sessions = $reachableServers | New-PSSession    
    }
    
    process {
        foreach ($session in $sessions) {        
            Invoke-Command -Session $session -ScriptBlock {
            $counter = 0;
              while($counter-le 10){
                $servicestatus = Get-Service -Name "bits" | select DisplayName, Status, PsComputerName, Name
              if ($servicestatus.Status -eq "Stopped") {                       
                     Start-Service -Name $servicestatus.Name                            
                    $result = $servicestatus.DisplayName + " is " + $servicestatus.Status               
                    Write-Host ($result);
                }else{
                    $result = $servicestatus.DisplayName + " is " + $servicestatus.Status
                     Write-Host ($result);
                
                } 
                $counter++;
                Start-Sleep -Seconds 5
              }          
            }
         
        }
    }
    
    end {
    
        Get-PSSession | Disconnect-PSSession | Remove-PSSession
        
    }
}
ServiceMonitor