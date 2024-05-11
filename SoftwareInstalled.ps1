function InstallChecker {  
    $reachableServers = Get-Content("./servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | Select-Object ComputerName, PingSucceeded 
   $sessions = $reachableServers | New-PSSession   
    $result = @() 
    ForEach ($sec in $sessions) {   
     
       
          $result+= Invoke-Command -Session $sec -ScriptBlock {
          hostname
          # Get-Service ClusSvc, SplunkForwardesr, McAfeeFramework, CSFalconService, FilterListenerService  | FT -AutoSize  
              Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Where-Object {$_.DisplayName -match "Trellix* | McAfee*"} | Select-Object DisplayName, DisplayVersion, InstallDate | FT -AutoSize    
               
           } 
        
       }  
     
     $result | Out-File -FilePath ".\InstalledSoftware.txt" -Force
      Get-PSSession | Disconnect-PSSession | Remove-PSSession
   }  
   InstallChecker