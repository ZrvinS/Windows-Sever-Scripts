Get-Service -Name BITS

New-Item -Name AmitTest -ItemType Directory -Path "\\Mcktorcfps01\wksmgmt\Public\"

New-Item -Name AmitTest -ItemType Directory -Path "\\Mcktorcfps01\wksmgmt\Public\"


$data = Get-Process | select Name, CPU, Id
$data | ConvertTo-Csv -NoTypeInformation

Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  
Where-Object {$_.DisplayName -match "Quest Change*"} | Select-Object DisplayName, DisplayVersion, InstallDate  