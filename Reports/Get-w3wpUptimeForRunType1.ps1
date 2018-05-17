<#######################################################################################################
Description: This script checks for W3wp which didn't restart in the last X days. (UptimeSince variable)
			 Script get Servers and return all Applications with up time more then defined in variable
Author: Shlomi Cohen, Amir Granot
Changelog: Replaced the iterative loop with concurrent jobs.
########################################################################################################>

###############
# Functions
###############

Function Get-ApplicationServersFromDB
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


##########
# Main
##########

clear

$UptimeSince = (Get-Date).AddDays(-2).ToString('MM/dd/yyyy') 
$serversList = Get-ApplicationServersFromDB | Select-Object @{N='ComputerName';E={$_.Name}},ApplicationPool
$ServerGroups = $serversList | Group-Object ComputerName

$result = $null
$jobErrors = $null

$ConcurrentJobsThreshold = 20
foreach($Server in $ServerGroups)
{
    $RunningJobs = @(Get-Job | Where-Object{ $_.State -eq 'Running' })

    if($RunningJobs.count -ge $ConcurrentJobsThreshold){
        $RunningJobs | Wait-Job -Any | Receive-Job -Wait -AutoRemoveJob -ErrorVariable +jobErrors -OutVariable +result
    }

    Invoke-Command -ComputerName $Server.name {
        $AllApplicationPools = $using:Server.Group | Select-Object -ExpandProperty ApplicationPool
        foreach($ApplicationPool in $AllApplicationPools){
            Get-WmiObject win32_process -filter "name = 'w3wp.exe'" | Where {
                $_.CommandLine -match "(?<=`")$ApplicationPool(?=`")"
            } | select ProcessId,name,@{N="PoolName";E={$ApplicationPool}}, PSComputerName,@{N="Uptime";E={$_.ConvertToDateTime($_.CreationDate)}} | Where {$_.Uptime -gt $UptimeSince}
        }
    } -AsJob
}

Get-Job | Receive-Job -Wait -AutoRemoveJob -ErrorVariable +jobErrors -OutVariable +result
      
