<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will  WWPN for the list of server saved on the servers.txt file

#>
$server = Get-Content(".\servers.txt");


$result = foreach($ser in $server){

    Invoke-Command -ComputerName $ser -ScriptBlock {

     Get-WmiObject win32_operatingsystem | select __SERVER | ft -AutoSize
     fcinfo

    }
}

$result | Out-File -FilePath ".\WWPN.txt"