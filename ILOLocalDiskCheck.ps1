cd C:\Users\***\Documents
Import-Module "C:\Program Files\WindowsPowerShell\Modules\hpeilocmdlets.4.4.0\HPEiLOCmdlets.psd1"
$ilolist = Get-Content -Path ".\ilolist.txt"
$ilouser = "***"
$ilopassword = "****"
$result = @()
$result += foreach ($ilo in $ilolist){
    $iloconnection = Connect-HPEiLO -Address $ilo -Username $ilouser -Password $ilopassword -DisableCertificateAuthentication
    $controler = Get-HPEiLOSmartArrayStorageController -Connection $iloconnection 
    $serverDrive = $controler.Controllers.LogicalDrives.DataDrives | select Id, CapacityGB, Model,MediaType,Description, Status  | FT -AutoSize
    $Health = $controler.Controllers.LogicalDrives.Status
    $State = $controler.Controllers.State
    
    Write-Output $ilo $serverDrive $Health $State
    Write-Output "--------------------------------------------------------------------------------------------------------------------------------"

}

$result | Out-File -FilePath "./iloriskresult2.txt" -force

