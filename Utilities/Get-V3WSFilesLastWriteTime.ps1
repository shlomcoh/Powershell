<#
	.SYNOPSIS
	Check the last write time of all the files in all the bin folders of all the V3 web servers
	
	.NOTES
	Written By Shlomi Cohen. 2.7.2017
	
	.EXAMPLE
	Get-V3WSFilesLastWriteTime
	
	Count Name                      Group
	----- ----                      -----
	88179 06/29/2017                {@{FullName=\\NJVV-WE103\TGS$\App\HotelWS\bin\AdaptorsCommon.dll; Date=06/29/2017}, ...
#>
Function Get-V3WSFilesLastWriteTime {
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


#Main
$Servers = Get-V3WSFilesLastWriteTime

$binFiles = foreach($Server in $Servers){
	get-childitem "\\$($Server.Name)\TGS`$\App\$($Server.ApplicationFolder)\bin\InfrastructureCache.dll"
}

$result = $binFiles | Select FullName,@{N='Date';E={Get-Date $_.LastWriteTime -format 'MM/dd/yyyy'}} | Group-Object Date

 write-output $result -PipelineVariable group |%{
    $outfile = "DeploymentReport_FilesWithDates-$($group.Name -replace '\/','-').txt"
    $group.Group | ForEach-Object{($_.FullName -split '\\')[2]} | Select -Unique | Out-File $outfile -Force
}

invoke-item .