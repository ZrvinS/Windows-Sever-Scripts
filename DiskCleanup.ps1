<#
	.SYNOPSIS
	    Clean up local server
	.DESCRIPTION
	    Clean up local server with delprof2 and logs removal.
	.EXAMPLE
		./run-cleanuplocal.ps1

#>


$tmp            = "C:\Temp\","C:\Windows\*.log","C:\Windows\Temp\","C:\Windows\Logs\","C:\hprepair_ALFRDCSIM01*","C:\Windows\SoftwareDistribution\","C:\Windows\CCM\logs\","C:\Windows\dd_*.txt","C:\Windows\hprepair*","C:\Windows\SET*.tmp","C:\BrightStor SRM Data\","C:\inetpub\logs\LogFiles\","C:\Program Files\CA\ARCserve Backup Client Agent for Windows\LOG\","C:\Program Files (x86)\CA\ARCserve Backup Agent for Open Files\LOGS\","C:\PerfLogs\","C:\Windows\MEMORY.DMP"
$LogDate        = get-date -format "MM-d-yy-HH"
#endregion Init
# -----------------------------------------------------------------------------
# Run Clean Up
# -----------------------------------------------------------------------------
#region Run
Start-Transcript -Path C:\Windows\Temp\$LogDate.log 

## Run delprof if it exists.
if (Test-Path "C:\Scripts\delprof2.exe") {     
        start-process cmd  -ArgumentList "/c 'c:\scripts|delprof2.exe /u /d:60 '" -Verb RunAs
}

## Cleanup tmp list
foreach ($item in $tmp ) {
        Get-ChildItem -path $item -ErrorAction SilentlyContinue | 
        Remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
}

## Delets all files and folders in user's Temp folder.  
Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | 
Remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue 
                     
## Remove all files and folders in user's Temporary Internet Files.  
Get-ChildItem "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue | 
Remove-item -force -recurse -ErrorAction SilentlyContinue 
                     
## Cleans IIS Logs if applicable. 
Get-ChildItem "C:\inetpub\logs\LogFiles\*" -Recurse -Force -ErrorAction SilentlyContinue | 
Remove-Item -Force -Verbose -Recurse -ErrorAction SilentlyContinue 

## Cleans CCM cache.
$resman = new-object -com "UIResource.UIResourceMgr"
$cacheInfo = $resman.GetCacheInfo()

#Enum Cache elements, compare date, and delete them
$cacheinfo.GetCacheElements()  | foreach {$cacheInfo.DeleteCacheElement($_.CacheElementID)}
                   
## Deletes the contents of the recycling Bin. 
$objShell = New-Object -ComObject Shell.Application  
$objFolder = $objShell.Namespace(0xA) 
$objFolder.items() | ForEach-Object { Remove-Item $_.path -ErrorAction Ignore -Force -Verbose -Recurse } 
Stop-Transcript