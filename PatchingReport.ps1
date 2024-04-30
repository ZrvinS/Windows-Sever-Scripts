<#
Contact(if any help required)
Author :- Amit Kumar Sunar
Email :- amit.sunar@nttdata.com

This Script will check if the mention KB is installed on the list of server saved on the servers.txt file

#>


$servers = Get-Content(".\serverlist.txt");
$kb = "KB5035849";
 
 
$result =  foreach($server in $servers){     
try{
     Get-HotFix -ComputerName $server | ?{$_.HotFixID -eq $kb } | select PSComputerName, HotFixID, InstalledOn, Description
 
  }catch{
    Write-Output "Mention KB not Installed"
}

 
}
 
$result | Out-File ".\PatchingResult.txt"