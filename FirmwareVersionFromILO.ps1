cd C:\Users\it0777su\Documents
Import-Module "C:\Program Files\WindowsPowerShell\Modules\hpeilocmdlets.4.4.0\HPEiLOCmdlets.psd1"
$ilolist = Get-Content -Path ".\ilolist.txt"
$ilouser = "Admin"
$ilopassword = "HPAdmin@10001"
$result = @()
$result += foreach ($ilo in $ilolist){
    $iloconnection = Connect-HPEiLO -Address $ilo -Username $ilouser -Password $ilopassword -DisableCertificateAuthentication
    $firmware = Get-HPEiLOFirmwareInventory -Connection $iloconnection
    $firmware.FirmwareInformation    
    Write-Output $ilo $serverDrive $Health $State
    Write-Output "--------------------------------------------------------------------------------------------------------------------------------"

}

$result | Out-File -FilePath "./iloFirmareVersion.txt" -force

