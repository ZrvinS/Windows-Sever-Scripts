



$servers = Get-Content(".\servers.txt") | Test-NetConnection | ? { $_.PingSucceeded -eq $true } | New-PSSession
$protocol = Get-Content(".\protocol.txt").Trim()
$Ciphersprotoraw = Get-Content(".\protocol2.txt").Trim()
$Hashprotoraw = Get-Content(".\protocol3.txt").Trim()

Invoke-Command -Session $servers   -ScriptBlock {

  $SecurityProto = ($using:protocol).Trim()
  $Ciphersproto = ($using:Ciphersprotoraw).Trim()
  $Hashproto = ($using:Hashprotoraw).Trim()
  hostname

  foreach ($proto in $SecurityProto) {            

    $securityServer = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$proto\Server").Enabled
    $securityClient = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$proto\Client").Enabled

    if ($securityServer -eq 0) {
      Write-Output "$proto is Disabled"
    }
    else {
      Write-Output "$proto is Enabled"
    }
      
    if ($securityClient -eq 0) {
      Write-Output "$proto is Disabled"
    }
    else {
      Write-Output "$proto is Enabled"
    }

  }

  foreach ($hash in $Hashproto) {
    
    $hashd = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\$hash").Enabled
          
    if ($hashd -eq 0) {
      Write-Output "$proto is Disabled"
    }
    else {
      Write-Output "$proto is Enabled"
    }
    
  }
  foreach ($Ciphers in $Ciphersproto) {          
      
    $Ciphers = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$Ciphers").Enabled
    
    if ($Ciphers -eq 0) {
      Write-Output "$proto is Disabled"
    }
    else {
      Write-Output "$proto is Enabled"
    }    
  }
} 
    


Get-PSSession | Disconnect-PSSession | Remove-PSSession