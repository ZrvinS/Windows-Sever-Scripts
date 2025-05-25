$server = Get-Content -Path "C:\Users\it0777su\Documents\servers.txt"

foreach($serv in $server){

Invoke-Command -ComputerName $serv -ScriptBlock {

$regpath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

New-ItemProperty -Path $regpath -Name "FeatureSettingsOverrideMask" -PropertyType DWord -Value 3 -Force
New-ItemProperty -Path $regpath -Name "FeatureSettingsOverride" -PropertyType DWord -Value 72 -Force

}
}

