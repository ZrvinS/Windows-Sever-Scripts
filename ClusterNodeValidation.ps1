$servers = Get-Content -Path ".\Servers.txt"

foreach($server in $servers){

    Invoke-Command -ComputerName $server -ScriptBlock {
        get-clusterGroup
    }
}