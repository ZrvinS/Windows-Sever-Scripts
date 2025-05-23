$server = Get-Content -Path ".\servers.txt"
$result = @()
foreach($serv in $server){
   $result+= Invoke-Command -ComputerName $serv -ScriptBlock {
        Get-BitLockerVolume | select VolumeType, Mountpoint, EncryptionPercentage,ProtectionStatus 
    }

}

$result | FT -AutoSize | Out-File -FilePath "./BitlockResult.txt" -Append -Force 