<#######################################################################################################
Description: This script get all applications from productMap and check for ServerCPU,ServerMemory 
			 and if its a single application on a server or multiple. script gets an array from DB and 
			 export CSV with ServerName,ApplicationCount,ApplicationName,Memory and Cpu
Author: Shlomi Cohen
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

$AllServersData = Get-ApplicationServersFromDB

write-output $AllServersData -PipelineVariable Server | ForEach-Object {
                $LogicalCores = Get-WmiObject -computername $Server.ServerName -class win32_processor -Property NumberOfLogicalProcessors | Measure NumberOfLogicalProcessors -Sum | select @{N="LogicalCores";E={$_.sum}} 
                Get-WMIObject -class Win32_PhysicalMemory -ComputerName $($server.ServerName) | Measure-Object -Property capacity -Sum |SELECT @{N='Memory';E={ % {[Math]::Round(($_.sum / 1GB),2)}}} |
                Add-Member -Name 'ServerName' -MemberType NoteProperty -Value $server.ServerName -PassThru |
                Add-Member -Name "LogicalCores" -MemberType NoteProperty -Value $LogicalCores.LogicalCores  -PassThru |
                Add-Member -Name "ApplicationName" -MemberType NoteProperty -Value $server.ApplicationName -PassThru

} -OutVariable result

$result | Group-Object -Property ServerName |select -Property Name,count,@{N='ApplicationName';E={if ($_.count -eq 1){$_.Group.ApplicationName}}},@{N='Memory (GB)';E={$_.Group.Memory[0]}},@{N='LogicalCores';E={$_.Group.LogicalCores[0]}} | export-csv -NoTypeInformation C:\temp\AllServersMemCPU.csv
