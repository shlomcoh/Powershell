<############################################ NAME: Clean-SundayPackage#############################################################
Description: This script goes through every folder we provide and delete "*.cs" "*.config" files that we don't need for deployment
it also delete tabconfig.xml file, and folders: Aircruise,Images,CSS from LMTWebui.
Author: Shlomi Cohen
Changes: If you change or add to the functionality please let me know so it can be reviewed
#>####################################################################################################################################

## dont delete ServiceInitializer.cs

Param ($Path)

if (Test-Path $path)
{
    #Remove read-only attribute 
    attrib -r $path\*.* /s  
    
    #Write and remove *.Cs files
    Get-ChildItem -path $path\* -include *.cs -exclude ServiceInitializer.cs,*.css -recurse | select FullName | Out-File $path\cs.txt
	Write-Host "Removing All *.cs except ServiceInitializer.cs" -ForegroundColor Green
    Get-ChildItem -path $path\* -include *.cs -exclude ServiceInitializer.cs,*.css -recurse | Remove-Item
    Write-host "the following *.cs was removed from package" -ForegroundColor Green
    Write-host (get-content ("C:\temp\6\cs.txt"))

    #Removing Folders and files from LMTWebui
    Write-Host "Removing tabconfig.xml" -ForegroundColor Green
    if (Test-Path $path\LMTWebUI\Modules\Customizable\TabConfig.xml){Remove-Item -path $path\LMTWebUI\Modules\Customizable\TabConfig.xml -force}
    Write-Host "Removing LMTWebUI Customizable->Css" -ForegroundColor Green
    if (Test-Path $path\LMTWebUI\Modules\Customizable\Css){Remove-Item -path $path\LMTWebUI\Modules\Customizable\Css -force -Recurse}
    Write-Host "Removing LMTWebUI AirCruise" -ForegroundColor Green
    if (Test-Path $path\LMTWebUI\AirCruise){Remove-Item -path $path\LMTWebUI\AirCruise -force -Recurse}
    Write-Host "Removing LMTWebUI Images" -ForegroundColor Green
    if (Test-Path $path\LMTWebUI\Images){Remove-Item -path $path\LMTWebUI\Images -force -Recurse}
    ############################################################

    $AllFolders = Get-ChildItem -path $Path | where {$_.Mode -like "d----*"} 
    
    write-output "These all the config files that was deleted"| Out-File $path\config.txt 
	Write-Host "Removing configuration files, check $path\config.txt once script is done to know what was deleted" -ForegroundColor Green
    foreach ($folder in $AllFolders)
    {
        
        $newpath = $folder.FullName 
        $FileExist = Get-ChildItem -path $newpath  | where {$_.Mode -notlike "d----*"} |  measure
        if ($FileExist.Count -ne 0)
        {
            get-ChildItem -path $newpath\* -include *.config -exclude *dll*,app.config | select -ExpandProperty FullName | Out-File $path\config.txt -append
            get-ChildItem -path $newpath\* -include *.config -exclude *dll*,app.config | Remove-Item
        }
        else # no files in the folder like (MobileWS/WebserviceV3)
        {
            $AllSubFolders = Get-ChildItem -path $Folder.FullName | where {$_.Mode -like "d----*"} 
            foreach ($OneSubFolder in $AllSubFolders)
            {
            $newsubpath = $OneSubFolder.FullName 
            $FileExist2 = Get-ChildItem -path $newsubpath  | where {$_.Mode -Notlike "d----*"} |  measure
            if ($FileExist2.Count -ne 0)
            {
                get-ChildItem -path $newsubpath\* -include *.config -exclude *dll*,app.config | select -ExpandProperty FullName | Out-File $path\config.txt -append
                get-ChildItem  -path $newsubpath\* -include *.config -exclude *dll*,app.config | Remove-Item
            }
            }
        }
    }

    if (Test-Path "$Path\config.txt") 
    {
        Write-host "the following *.config files was removed from package" -ForegroundColor Green
        Write-host (get-content ("$Path\config.txt"))
        
    }

}