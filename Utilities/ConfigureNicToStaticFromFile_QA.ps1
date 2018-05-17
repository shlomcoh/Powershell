$NIC = Get-WMIObject Win32_NetworkAdapterConfiguration  | where{$_.IPEnabled -eq $true -and $_.DHCPEnabled -eq $True} 
    
if ($nic)
{    
    Write-Host "Found DHCP Enabled, Changing to Static IP." -ForegroundColor Green
    $nicfromFile = Import-Csv C:\temp\nic.csv
    $pat = "^[a-zA-Z]"
    $ips = $nicfromFile.IPAddress -split " "  | where {$_ -notmatch $pat}
    $IPSubnet= $nicfromFile.IPSubnet -split " " 
    $gateway = $nicfromFile.DefaultIPGateway 
    $dns = $nicfromFile.DNSServerSearchOrder  -split " " 
    $mask = @()
    $i = 0
    foreach ($ip in $ips)
    {
        $mask += $IPSubnet[$i] 
        $i++
    }
    Write-Host "Ips: $ips,gateway: $gateway, DNS: $DNS,Subnet: $mask" -ForegroundColor Green
    $NIC.EnableStatic($ips, $mask) 
    $NIC.SetGateways($gateway) 
    $NIC.SetDNSServerSearchOrder($dns) 
    $NIC.SetDynamicDNSRegistration("FALSE")  
}
else
{
    Write-Host "no DHCP" -ForegroundColor Green
}

    