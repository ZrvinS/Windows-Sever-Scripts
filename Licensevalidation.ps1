$reachableServers = Import-Csv -Path "./servers.csv"


try{
$sessions = $reachableServers | New-CimSession -ErrorAction SilentlyContinue -ErrorVariable sesfail
$sesfail | Out-File -FilePath "./Failed.txt" -Force

}catch{
  
  Write-Host "Session Fail" 
    
}

$result = @()
foreach($sec in $sessions){

    $result += Get-CimInstance SoftwareLicensingProduct -CimSession $sec | ?{$_.Name -like "Windows*" -and $_.LicenseStatus -eq 1} | select PSComputerName, @{n="ServerLicense";e={$_.Name.Substring(0,[math]::min(30,$_.Name.Length))}}, Description, LicenseStatus, @{n="Activation";e={"Activation"}} | ft -AutoSize

}
$result | Out-File -FilePath "./Licensestatus.txt" -Force

Get-CimSession | Remove-CimSession