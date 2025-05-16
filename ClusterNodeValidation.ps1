$servers = Get-Content -Path ".\Servers.txt"
$result =@()
foreach($server in $servers){

  $result += Invoke-Command -ComputerName $server -ScriptBlock {
        
        $result = Get-ClusterGroup | select Name, Ownernode, status
        
        $ownerNode = $result | select -ExcludeProperty Onwernode
        $ownerNode | select -Unique ownernode       

    }
}