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