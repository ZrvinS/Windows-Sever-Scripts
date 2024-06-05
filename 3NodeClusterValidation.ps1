$servers = Get-Content ".\servers.txt"

function TestConnection {
    param(
        [String]
        $computerName
    )
    $result = Test-Connection -ComputerName $computerName -Count 1 -ErrorAction SilentlyContinue
    return $result
}

$results = @()

foreach ($Server in $servers) {
    $connectionTest = TestConnection -computerName $Server
    if ($connectionTest) {
        $session = New-PSSession -ComputerName $Server -ErrorAction SilentlyContinue
        if ($session) {
            $clusterNodes = Invoke-Command -Session $session -ScriptBlock {
                $cluster = Get-ClusterNode | select -ExpandProperty Name
                $ClusterNodes = @()

                if ($cluster.Count -ge 3) {
                    $ClusterNodes += [PSCustomObject]@{
                        ServerName   = $env:COMPUTERNAME
                        ClusterNode1 = $cluster[0]
                        ClusterNode2 = $cluster[1]
                        ClusterNode3 = $cluster[2]
                        IsThreeNode  = $true
                    }
                }
                else {
                    $ClusterNodes += [PSCustomObject]@{
                        ServerName   = $env:COMPUTERNAME
                        ClusterNode1 = if ($cluster.Count -ge 1) { $cluster[0] } else { $null }
                        ClusterNode2 = if ($cluster.Count -ge 2) { $cluster[1] } else { $null }
                        ClusterNode3 = if ($cluster.Count -ge 3) { $cluster[2] } else { $null }
                        IsThreeNode  = $false
                    }
                }

                return $ClusterNodes
            } -ErrorAction SilentlyContinue

            $results += $clusterNodes
            Disconnect-PSSession -Session $session
            Remove-PSSession -Session $session
        }
        else {
            Write-Output "Failed to create session with $Server"
        }
    }
    else {
        Write-Output "Server $Server not reachable"
    }
}

# Export results to a file
$results | Export-Csv -Path ".\ClusterNodesReport.csv" -Force -NoTypeInformation

Write-Output "Cluster nodes report has been exported to ClusterNodesReport.csv"
