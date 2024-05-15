
[xml]$xfunction = Get-Content(".\config.xml");
   $execute = $xfunction.configuration.function
function protocolChecker(){
    

[xml]$config = Get-Content(".\config.xml");
 
    $xserver = $config.configuration.GlobalVariables.server
    Write-Output $xserver

$xmlGbariable = ($config.configuration.GlobalVariables.protocols).Split(",")
 $xmlGV = @()
    $xmlGbariable.ForEach{
       $xmlGV += $_.trim()
    }

    $xmlGV.ForEach{

      $protoStatus = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$_\$xserver").Enabled
        if($protoStatus -eq 1){
            Write-Output "$($_) Enabled"
        }else{
             Write-Output "$($_) Disabled"
        }

    }
}

function consolemessage(){
    
    Write-Output "This is a message from Console"
}

$toexecute = $execute.Split(",")
Write-Output $toexecute

foreach ($exect in $toexecute){
    & $exect
}
