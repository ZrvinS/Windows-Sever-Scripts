$serverlist = Get-Content -Path "C:\temp\servers.txt"
$result = @();
$result += Invoke-Command -ComputerName $serverlist -ScriptBlock {


    Get-HotFix | Sort-Object InstalledOn -Descending | select HotfixID, InstalledBy, InstalledOn -First 3
}

$result | FT -AutoSize | Out-File -FilePath "C:\temp\result.txt"