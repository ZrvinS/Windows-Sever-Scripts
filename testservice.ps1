Remove-Module mailmodule; Import-Module ".\mailmodule.psm1"
while ($true) {
    $servicesttaus = Get-Service -Name "wercplsupport" | select Status, Name
 
 if ($servicesttaus.Status -eq "Stopped") {
    <# Action to perform if the condition is true #>
    try {
        Write-Host "Service is $($servicesttaus.Status)"
        Start-Service -Name $servicesttaus.Name -ErrorAction SilentlyContinue -ErrorVariable error
    }
    catch {
        sendmail -bodmsg "The Service $($servicesttaus.Name) is $($servicesttaus.Status) Please Take Necessary Action $($error.Message)"
        Start-Sleep -Seconds 120
        <#Do this if a terminating exception happens#>
    }
    
    
 }else{
    Write-Host "Service is running Fine"
 }
  
 Start-Sleep -Seconds 3
}


