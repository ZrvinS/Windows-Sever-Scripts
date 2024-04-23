$server = Get-Content("./servers.txt");


$result =  foreach ($ser in $server) {

    if (Test-Connection -ComputerName $ser -count 3 -quiet){

        Get-WmiObject Win32_logicaldisk -ComputerName $ser | select DriveID,  SystemName, @{n="Size/GB"; e={[System.Math]::Round($_.Size/1gb,2)}}, @{n="FreeSpace/GB"; e={[System.Math]::Round($_.FreeSpace/1gb,2)}}
    }else{

        Write-Output("$ser Server down");
    }
}

$result | Out-File -FilePath "./output.txt"
