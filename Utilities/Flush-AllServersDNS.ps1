$Servers = @"
Server1
Server2
"@ -split [environment]::newline | ForEach-Object{$_.trim()}
$ClusterName= ""
$ClusterIP = ""
$NewClusterIP = ""
<##### From Windows server 2012 and above
#Resolve-DnsName -name sqlcluster01 -Server dc11.thdc1.local
#Resolve-DnsName -name sqlcluster01 -Server dc12.thdc1.local
#Resolve-DnsName -name sqlcluster01 -Server dc13.thdc1.local
#Resolve-DnsName -name sqlcluster01 -Server dc14.thdc1.local
######>

Write-Host "Check if DNS Record for $ClusterName exist"
Invoke-Command -ComputerName $Servers -ScriptBlock {$Exist = ipconfig /displaydns | Select-String "$ClusterIP" -Quiet
if ($Exist) {Return $true} else {Return $false}} | SELECT PSComputerName,@{n='Exist';E={$_.ToString()}}
Write-Host "`nFlushing DNS on all servers and pinging $ClusterName" -ForegroundColor Yellow
Invoke-Command -ComputerName $Servers -ScriptBlock {ipconfig /flushdns ; Test-Connection sqlcluster01 -Count 1} | Out-Null
Write-Host "`nCheck if DNS Record for New $ClusterName exist`n" -ForegroundColor Yellow
Invoke-Command -ComputerName $Servers -ScriptBlock {$Exist = ipconfig /displaydns | Select-String "$NewClusterIP"  -Quiet
if ($Exist) {Return $true} else {Return $false}} | SELECT PSComputerName,@{n='Exist';E={$_.ToString()}}
 
