<#
	.SYNOPSIS
	Check AllowKeepAlive on IIS level.
	
	.NOTES
	added section to Set IIS allowKeepAlive=True at the end of the script
	Written By Shlomi Cohen. 3.26.2018
	
	
#>
Function Get-DataFromProductMapDB
{
    Param (
    $RemoteDBServer = "",
    $DB = "",
    $userName = "",
    $password = "",
    $query = @"
"@
)
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

$servers = Get-DataFromProductMapDB
#$servers = $servers[0..4]
write-output $servers -PipelineVariable Server | foreach-object { 
    $PoolName = $Server.SiteName
     
    Invoke-Command -ComputerName $server.name -AsJob -ScriptBlock {
    param($Pool) 
        
    $exist = Invoke-Expression "c:\windows\system32\inetsrv\appcmd.exe list config -section:system.webServer/httpProtocol" | select-string "allowkeepalive" #| where  {$_.Line -match 'false'}
    if ($exist -match 'false') { $ExistInIIS = 'false'} elseif ($exist -match 'true') { $ExistInIIS = 'true'} else { $ExistInIIS = 'DoesNotExist'}
    $Exist2 = Invoke-Expression "c:\windows\system32\inetsrv\appcmd.exe list config $Pool -section:system.webServer/httpProtocol" | select-string "allowkeepalive" #| where  {$_.Line -match 'false'}
    #if ($ExistInSite) {Return $true} else {Return $false}
    if ($Exist2 -match 'false') { $ExistInSite = 'false'} elseif ($Exist2 -match 'true') { $ExistInSite = 'true'} else { $ExistInSite = 'DoesNotExist'}
    if ($ExistInIIS -eq 'DoesNotExist')
    {
        $IsInheritValue_IIS = get-WebConfigurationProperty "/system.webServer/httpProtocol" -name allowKeepAlive | select -ExpandProperty Value
        $ExistInIIS = 'Inherit: ' + $IsInheritValue_IIS 
    }
        
    $ReturnValue = New-Object -TypeName psobject -Property @{
        'IIS' = $ExistInIIS
        'Site' = $ExistInSite
    }

        $ReturnValue
    }  -ArgumentList $PoolName | SELECT PSComputerName, IIS, Site 

    if ((Get-job -State 'Running').Count -gt 25)
        {
            sleep 3
        }

    }

get-job | Receive-Job -Wait -OutVariable IISAllowKeepAlive -AutoRemoveJob -ErrorVariable err2

$IISAllowKeepAlive | select PSComputerName,Site,IIS | Export-Csv -Path D:\IISAllowKeepAlive.csv -NoTypeInformation

<################# Set IIS allowKeepAlive=True####################
$IISAllowKeepAliveFalse  = $IISAllowKeepAlive | where {$_.IIS -match 'False'}
foreach ($iisFalse in $IISAllowKeepAliveFalse)
{
    Invoke-Command -ComputerName $server.name -AsJob -ScriptBlock {Invoke-Expression 'c:\windows\system32\inetsrv\appcmd.exe set config -section:system.webServer/httpProtocol /allowKeepAlive:"True"'}
}
####################>