$sourceApp = "\\lnk-fs99\install\Qualys Agent\Qualys Agent 6.1\*"
       $destinationpath = "C:\Temp" 
if (-Not (Test-Path $destinationpath)){
    New-Item -Path $destinationpath -ItemType Directory | Out-Null 
    Write-Host "Temp created"
}

Copy-Item -Path $sourceApp -Destination $destinationpath -Recurse -Force

Write-Host "Finding App..."
$app = Get-WmiObject Win32_Product | ? {$_.Name -like "Qualys*"}

if($app){
    Write-Host "App Found" $app.Name
    Write-Host "UnInstalling App"
    $app.Uninstall()
    Write-Host "Uninstall Completed"
}
else {
    Write-host "No Application Found, Proceeding to Installation"
}

Set-Location -Path $destinationpath

& .\QualysCloudAgent.exe "CustomerId={**}" "ActivationId={**}" "WebServiceUri=https://**/"


 Write-Host "Qualys Agent Installation Completed"
