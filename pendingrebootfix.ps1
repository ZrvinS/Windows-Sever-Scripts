net stop wuauserv
net stop bits
net stop cryptsvc
net stop trustedinstaller

ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" /f
reg delete "HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile" /f

net start trustedinstaller
net start cryptsvc
net start bits
net start wuauserv

DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow