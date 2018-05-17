<###########################################################
this set of commands are the minimum for allowing PS ro run 
from local or a remote computer
if remote still doesn't work need to check open ports
###########################################################>
enable-psremoting –force
Set-ExecutionPolicy Unrestricted –force
Set-Item WSMan:\localhost\Client\TrustedHosts *
Restart-Service WinRM
exit