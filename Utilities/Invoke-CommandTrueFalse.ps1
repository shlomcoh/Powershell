<#
	.SYNOPSIS
	Run ScriptBlock on Remote Servers and return True if exist and false if not.
	
	.NOTES
	Written By Shlomi Cohen.
	
	.EXAMPLE
	in scriptBlock: Get-Content C:\windows\System32\drivers\etc\hosts | Select-String 'sqlcluster01' -Quiet
	
	Result:
    PSComputerName Exist
    -------------- -----
    njpb-maindb02  False
#>

$Servers = @"  
Server1
Server2
"@ -split [environment]::newline | ForEach-Object{$_.trim()}


Invoke-Command -ComputerName $Servers -ScriptBlock {$Exist = "EnterScriptHere"
                                                    if ($Exist) {Return $true} else {Return $false}} | SELECT PSComputerName,@{n='Exist';E={$_.ToString()}
                                                   }