$servers = Get-Content -Path ".\Servers.txt"
$result = @()
$result = foreach($server in $servers){

  Invoke-Command -ComputerName $server -ScriptBlock {
        
        $resultinter = Get-ClusterGroup | select Name, Ownernode, status
        
        $ownerNode = $resultinter | select -ExcludeProperty Onwernode
        $ownerNode | select -Unique ownernode        

    } 
    
}
 $result | Out-File -FilePath "ClusterNodeResult.txt" -Force
