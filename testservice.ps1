Remove-Module mailmodule; Import-Module ".\mailmodule.psm1"
while ($true) {
    $servicesttaus = Get-Service -Name "okta Auto Update Service" | select Status, Name
 
 if ($servicesttaus.Status -eq "Stopped") {
    <# Action to perform if the condition is true #>
    try {
       
        Start-Service -Name $servicesttaus.Name -ErrorAction Stop 
        $newstatus = Get-Service $servicesttaus.Name
        Write-Output $newstatus 
    }
    catch {
        sendmail -Messagetosend "The Service $($servicesttaus.Name) is $($servicesttaus.Status) Please Take Necessary Action $($error.Message)"
        <#Do this if a terminating exception happens#>
        Write-Output "Service Start Failed"
    }
    
    
 }else{
    Write-Host "Service is running Fine"
 }
  
 Start-Sleep -Seconds 3
}

