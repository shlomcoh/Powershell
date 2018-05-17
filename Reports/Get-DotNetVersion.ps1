<#
    Generate a report of the version of Dot Net that is installed on remote servers
    The list of servers can be loaded from a file, or retrieved from the AD

    Amir Granot
    25.6.2017
#>

## ption 1: 
$FilePath = read-host "Enter full name (with path) of a text file containing a list of servers"
#$FilePath = "$env:USERPROFILE\Documents\serverslist.txt"
Test-Path $FilePath -PathType Leaf -ErrorAction Stop

$servers = Get-Content $FilePath | Sort-Object -Unique

## Option 2: 
#$servers = Import-csv "$env:USERPROFILE\Desktop\PMAllServers.csv" | Sort-Object -Property ServerName,NetworkID -Unique | Select-Object -ExpandProperty Name

## Option 3: Using Active Directory Cmdlets
## Requires Module ActiveDirectory (if the module is missing, it can be installed via Add-WindowsFeature RSAT-AD-PowerShell)
#$MonthAgo = (Get-Date).AddDays(-30)
#$servers = Get-ADComputer -Filter {OperatingSystem -like "*Server*"} -Properties PasswordLastSet | Where-Object{ $_.PasswordLastSet -gt $MonthAgo } | Select-Object -ExpandProperty Name

Function Get-DotNet{
<#
    .NOTES
    Source:    https://stackoverflow.com/questions/3487265/powershell-script-to-return-versions-of-net-framework-on-a-machine
#>
    Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
    Get-ItemProperty -name Version,Release -EA 0 |
    Where { $_.PSChildName -match '^(?!S)\p{L}'} |
    Select PSChildName, Version, Release, @{
      name="Product"
      expression={
          switch -regex ($_.Release) {
            "378389" { [Version]"4.5" }
            "378675|378758" { [Version]"4.5.1" }
            "379893" { [Version]"4.5.2" }
            "393295|393297" { [Version]"4.6" }
            "394254|394271" { [Version]"4.6.1" }
            "394802|394806" { [Version]"4.6.2" }
            "460798" { [Version]"4.7" }
            {$_ -gt 460798} { [Version]"Undocumented 4.7 or higher, please update script" }
          }
        }
    }
}

## Syntax ${function:...} is to include locally defined function as scriptblock for invoke-command
## ErrorVariable can be used to further investigate the failure of commands ($failed.TargetObject to get the list of servers that threw the errors)
$DNResult = Invoke-Command -ComputerName $servers.trim() -ScriptBlock ${function:Get-DotNet} -ErrorVariable failed 

$DNResult | Group-Object PSComputerName | Select-Object Name,@{N='DNVersion'; E={$_.Group.Version | Sort-Object -Descending | Select -First 1}} | Sort-Object Name | export-csv $env:USERPROFILE\Desktop\DotNetResult.csv -NoTypeInformation -Verbose -force