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

& .\QualysCloudAgent.exe "CustomerId={a25f9287-d937-6cd2-81dd-de9162c0212c}" "ActivationId={d4a1144e-c60a-4c4b-98e9-00910fce11e6}" "WebServiceUri=https://qagpublic.qg1.apps.qualys.eu/CloudAgent/"


 Write-Host "Qualys Agent Installation Completed"