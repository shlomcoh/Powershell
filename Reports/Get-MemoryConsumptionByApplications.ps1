<#######################################################################################################
Description: This script get all applications from ProductMap and check for memory consumption.
             the script returns 2 different objects: 1) Memory consumption by ApplicationType
                                                     2) Memory Consumption by ApplicationName
Author: Shlomi Cohen
########################################################################################################>

###############
# Functions
###############

function get-standarddeviation {            
[CmdletBinding()]            
param (            
  [double[]]$numbers            
)            
            
    $avg = $numbers | Measure-Object -Average | select Count, Average            
            
    $popdev = 0            
            
    foreach ($number in $numbers){            
      $popdev +=  [math]::pow(($number - $avg.Average), 2)            
    }            
            
    $sd = [math]::sqrt($popdev / ($avg.Count-1))            
$sd            
}


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

$AllServersData = Get-ApplicationServersFromDB

write-output $AllServersData -PipelineVariable Server | ForEach-Object {
    if ($Server.NetworkID -eq '2')
    {
        if ($Server.ProcessName -match 'w3wp')
        {        
            Invoke-Command -ComputerName $server.ServerName -AsJob {Get-WmiObject win32_process -filter "name = 'w3wp.exe'"  | Where {$_.CommandLine -match "(?<=`")$($using:server.ApplicationPool)(?=`")"} | SELECT @{n='Mem (GB)';e={($_.WS/1GB)}}, PSComputerName |
            Add-Member -Name 'ApplicationName' -MemberType NoteProperty -Value $using:Server.ApplicationName -PassThru |
            Add-Member -Name 'ApplicationType' -MemberType NoteProperty -Value $using:Server.ApplicationType -PassThru |
            Add-Member -Name 'ApplicationPool' -MemberType NoteProperty -Value $using:Server.ApplicationPool -PassThru |
            Add-Member -Name 'WindowsServiceName' -MemberType NoteProperty -Value $using:Server.WindowsServiceName -PassThru }
        }
        else 
        {
             if ($Server.ApplicationType -match 'Autotask')
            {
                Invoke-Command -ComputerName $server.ServerName -AsJob {Get-WmiObject win32_process -filter "name like '%$($using:server.ProcessName)%'" | Where {$_.CommandLine -match $($using:server.ApplicationName)} | SELECT @{n='Mem (GB)';e={($_.WS/1GB)}}, PSComputerName |
                Add-Member -Name 'ApplicationName' -MemberType NoteProperty -Value $using:Server.ApplicationName -PassThru |
                Add-Member -Name 'ApplicationType' -MemberType NoteProperty -Value $using:Server.ApplicationType -PassThru |
                Add-Member -Name 'ApplicationPool' -MemberType NoteProperty -Value $using:Server.ApplicationPool -PassThru |
                Add-Member -Name 'WindowsServiceName' -MemberType NoteProperty -Value $using:Server.WindowsServiceName -PassThru }
            }   
            else
            {
            Invoke-Command -ComputerName $server.ServerName -AsJob {Get-WmiObject win32_process -filter "name like '%$($using:server.ProcessName)%'" | Where {$_.CommandLine -match "$($using:server.WindowsServiceName)\\"} | SELECT @{n='Mem (GB)';e={($_.WS/1GB)}}, PSComputerName |
            Add-Member -Name 'ApplicationName' -MemberType NoteProperty -Value $using:Server.ApplicationName -PassThru |
            Add-Member -Name 'ApplicationType' -MemberType NoteProperty -Value $using:Server.ApplicationType -PassThru |
            Add-Member -Name 'ApplicationPool' -MemberType NoteProperty -Value $using:Server.ApplicationPool -PassThru |
            Add-Member -Name 'WindowsServiceName' -MemberType NoteProperty -Value $using:Server.WindowsServiceName -PassThru }
            
            }
        }
        if ((Get-job -State 'Running').Count -gt 25)
        {
            sleep 3
        }
        
    }
}

get-job | Receive-Job -Wait -OutVariable result -AutoRemoveJob -ErrorVariable err2

$result.Count

$result | export-csv -NoTypeInformation C:\temp\AllServersDataLANNew.csv
$result | Group-Object -Property ApplicationType | select -Property @{N='ApplicationType';e={$_.Name}},Count,@{N='AVG (GB)';E={($_.Group | Measure-Object -Average -Property 'Mem (GB)').Average}},@{N='Mimimum (GB)';E={($_.Group | Measure-Object -Minimum -Property 'Mem (GB)').Minimum}},@{N='Maximum (GB)';E={($_.Group | Measure-Object -Maximum -Property 'Mem (GB)').Maximum}},@{N='standarddeviation (GB)';E={get-standarddeviation $_.Group.'Mem (GB)'}} | sort -Property ApplicationType |export-csv -NoTypeInformation C:\temp\AllServersLANBYType.csv
$result | Group-Object -Property ApplicationName| select -Property @{N='ApplicationName';e={$_.Name}},Count,@{N='AVG (GB)';E={($_.Group | Measure-Object -Average -Property 'Mem (GB)').Average}},@{N='Mimimum (GB)';E={($_.Group | Measure-Object -Minimum -Property 'Mem (GB)').Minimum}},@{N='Maximum (GB)';E={($_.Group | Measure-Object -Maximum -Property 'Mem (GB)').Maximum}},@{N='standarddeviation (GB)';E={get-standarddeviation $_.Group.'Mem (GB)'}} | sort -Property ApplicationName  | export-csv -NoTypeInformation C:\temp\AllServersLANBYName.csv




