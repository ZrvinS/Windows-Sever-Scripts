$splunk = "splunkforwarder-9.0.0.1-9e907cedecb1-x64-release.msi"
$splunkpath = "\\g7w10002s\E$\Software\Splunk old_DONOTDELETE\$($splunk)"
Copy-Item -Path $splunkpath -Destination "C:\temp" -Force 
$splunklocalpath = "C:\Temp\$($splunk)"
msiexec.exe /I $splunklocalpath DEPLOYMENT_SERVER="splunk-deployment.corp.hpicloud.net:8089" AGREETOLICENSE=yes LAUNCHSPLUNK=1 SERVICESTARTTYPE=auto /quiet
