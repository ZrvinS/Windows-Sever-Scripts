Get-Service -Name W3SVC | select Name, Status, StartType

Get-HotFix | Sort-Object InstalledOn -Descending | select -First 3