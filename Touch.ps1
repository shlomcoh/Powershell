clear
Write-Host "This function will change the last write time for the entire folder" -foregroundcolor Green
$FolderPath= Read-Host "please enter folder's path (ex; c:\xxx)"
$Date = Read-Host "please enter valid date in the following format: MM.DD.YYYY"
if ([string]$date -as [DateTime])  
{
    $SplitDate = $Date -split "\."
}
else
{
    Write-Host "not a valid date"
}

gci $FolderPath -Include *.* -Recurse | % { if($_.IsReadOnly){$_.IsReadOnly= $false} }

Get-ChildItem $FolderPath -recurse -filter *.* | % { $_.LastWriteTime = Get-Date -Year $SplitDate[2] -Month $SplitDate[0] -Day $SplitDate[1] }