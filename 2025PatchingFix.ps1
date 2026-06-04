$server = Get-Content -Path "C:\Temp\servers.txt"

foreach($serv in $server){

Invoke-Command -ComputerName $serv -ScriptBlock {

$regpath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate"
$regpath2 = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"

New-ItemProperty -Path $regpath -Name "SetPolicyDrivenUpdateSourceForFeatureUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $regpath -Name "SetPolicyDrivenUpdateSourceForQualityUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $regpath -Name "SetPolicyDrivenUpdateSourceForDriverUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $regpath -Name "SetPolicyDrivenUpdateSourceForOtherUpdates" -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path $regpath2 -Name "UseUpdateClassPolicySource" -PropertyType DWord -Value 1 -Force


}
}