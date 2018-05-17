<#######################################################################################################
Description: This script get all Nic configuration from all servers in the list and save them to c:\Temp\Nics.csv
Author: Shlomi Cohen
Comments: the file VMServers.csv was exported from VMCenter

########################################################################################################>

Function Get-ApplicationServersFromDB{
    $RemoteDBServer = ""
    $DB = ""
    $userName = ""
    $password = ""
    $query = @" 
"@

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Integrated Security=False;Persist Security Info=False;Initial Catalog=$DB;Data Source=$RemoteDBServer;User ID=$userName;Password=$password"
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $query
    $SqlCmd.CommandTimeout = '60'
    $SqlCmd.Connection = $SqlConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet) | Out-Null
    $SqlConnection.Close()
    $AllServersData  = $DataSet.Tables[0].Rows
    return $AllServersData
}


$servers = Import-Csv C:\Temp\VMServers.csv 
$QAservers = $servers.Name | Where {$_ -match 'tlvv-'}
### get nic configuration remotely and create local file with nic configuration under C:\Temp\
foreach ($server in $QAServers)
{
    if ((Test-Connection -Count 1 -ComputerName $server -ErrorAction SilentlyContinue).IPV4Address)
    {
        Invoke-Command -ComputerName $server -ScriptBlock { 
            if (-not (Test-Path "c:\Temp")){ mkdir -Path c:\temp -Force}
            $nic = Get-WMIObject Win32_NetworkAdapterConfiguration  | 
            where {$_.IPEnabled -eq $true -and $_.DHCPEnabled -eq $False} | 
            select -Property @{N='IPAddress';E={$_.IPAddress}},@{N='DefaultIPGateway';E={$_.DefaultIPGateway}},@{N='IPSubnet';E={$_.IPSubnet}},@{N='DNSServerSearchOrder';E={$_.DNSServerSearchOrder}} 
            $nic | export-csv c:\temp\nic.csv -NoTypeInformation 
            return $nic
            } | Select PScomputername,IPAddress,DefaultIPGateway,IPSubnet,DNSServerSearchOrder | Export-Csv "c:\Temp\Nics.csv" -NoTypeInformation -Append
    }
    else {Write-host "$server not avail"}

}
