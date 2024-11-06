$server =  Get-Content ".\servers.txt"
 
$result = @()
 
$result += foreach ($serv in $server){
 
Invoke-Command -ComputerName $serv -ScriptBlock {
     Get-WindowsFeature | ?{$_.Name -like "*Defender-F*"} 
}

}
 
$result | FT -AutoSize |  Out-File -FilePath "./result.txt"  -Force  