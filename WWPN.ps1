
$server = Get-Content(".\servers.txt");


$result = foreach($ser in $server){

    Invoke-Command -ComputerName $ser -ScriptBlock {

     Get-WmiObject win32_operatingsystem | select __SERVER | ft -AutoSize
     fcinfo

    }
}

$result | Out-File -FilePath ".\WWPN.txt"