Remove-Item -Path "C:\ProgramData\PuppetLabs\puppet\etc\ssl" -Recurse -ErrorAction SilentlyContinue
$content = Get-Content C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf -ErrorAction SilentlyContinue

$content = @"
[main]
server = cma.globelifeinc.com
ca_server = awtmprnucsco01.tmk.ent.lc
autopush = false
"@

$content | Out-File -FilePath "C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf" -Force


Restart-Service -Name puppet
