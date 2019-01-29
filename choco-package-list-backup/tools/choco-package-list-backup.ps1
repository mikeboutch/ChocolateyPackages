# choco-package-list-backup.ps1 (to local and cloud) by Bill Curran
# I couldn't have done this without the list parsing from Ammaar Limbada found at https://gist.github.com/alimbada/449ddf65b4ef9752eff3
# LICENSE: GNU GPL v3 - https://www.gnu.org/licenses/gpl.html
# ROADMAP:
# Add other cloud services support by request
# FYI: CAN NOT save/get installed package parameters as they are encrypted :(
# Open to suggestions - open a GitHub issue please if you have a suggestion/request.

$CPLBver        = "2018.08.23" # Version of this script
$Date           = Get-Date -UFormat %Y-%m-%d

# Import preferences - see choco-package-list-backup.xml in Chocolatey's bin dir
[xml]$ConfigFile = Get-Content "$env:ChocolateyInstall\bin\choco-package-list-backup.xml"

$PackagesListFile = $ConfigFile.Settings.Preferences.PackagesListFile
$SaveFolderName = $ConfigFile.Settings.Preferences.SaveFolderName
$SaveVersions = $ConfigFile.Settings.Preferences.SaveVersions
$AppendDate = $ConfigFile.Settings.Preferences.AppendDate
$CustomPath = $ConfigFile.Settings.Preferences.CustomPath
$SaveAllProgramsList = $ConfigFile.Settings.Preferences.SaveAllProgramsList
$AllProgramsListFile = $ConfigFile.Settings.Preferences.AllProgramsListFile

$UseCustomPath = $ConfigFile.Settings.Preferences.UseCustomPath 
$UseDocuments = $ConfigFile.Settings.Preferences.UseDocuments
$UseHomeShare = $ConfigFile.Settings.Preferences.UseHomeShare 
$UseBox = $ConfigFile.Settings.Preferences.UseBox
$UseDropbox = $ConfigFile.Settings.Preferences.UseDropbox
$UseGoogleDrive = $ConfigFile.Settings.Preferences.UseGoogleDrive
$UseiCloudDrive = $ConfigFile.Settings.Preferences.UseiCloudDrive
$UseNextcloud = $ConfigFile.Settings.Preferences.UseNextcloud
$UseOneDrive = $ConfigFile.Settings.Preferences.UseOneDrive
$UseownCloud = $ConfigFile.Settings.Preferences.UseownCloud
$UseReadyCLOUD = $ConfigFile.Settings.Preferences.UseReadyCLOUD
$UseResilioSync = $ConfigFile.Settings.Preferences.UseResilioSync
$UseSeafile = $ConfigFile.Settings.Preferences.UseSeafile
$UseTonidoSync = $ConfigFile.Settings.Preferences.UseTonidoSync

if ($AppendDate -eq "true"){
    if ($PackagesListFile -eq "packages.config"){
		 $PackagesListArchival = "packages_$Date.config"
		} else {
		  $PackagesListArchival = $PackagesListFile+"_$Date.config"
		}
 }

# Check the path to save packages.config and create if it doesn't exist
Function Check-SaveLocation{
    $CheckPath = Test-Path $SavePath
  If ($CheckPath -match "False")
     {
      New-Item $SavePath -Type Directory -force | out-null
     }   
    }

# Copy persistentpackages.config if it exists to the same location as packages.config
Function Check-PPConfig{
    $CheckPPSource = Test-Path $Env:ChocolateyInstall\config\persistentpackages.config
	If ($CheckPPSource -match "True"){
	   Copy-Item $Env:ChocolateyInstall\config\persistentpackages.config $SavePath -force | out-null
	   Write-Host "  * $SavePath\persistentpackages.config SAVED!" -ForegroundColor green 
    }
  }
	
# Copy InstChoco.exe if it exists to the same location as packages.config for super duper easy re-installation
$InstChoco = "$Env:ChocolateyInstall\lib\instchoco\tools\InstChoco.exe" # location of InstChoco.exe if it exists
Function Check-InstChoco{
    $CheckICSource = Test-Path $InstChoco
	If ($CheckICSource -match "True"){
	   $CheckICDest = Test-Path $SavePath\InstChoco.exe
	   If ($CheckICDest -match "False")
	      {
	       Copy-Item $InstChoco $SavePath -force | out-null
		   Write-Host "  * $SavePath\InstChoco.exe SAVED!" -ForegroundColor green 
	      } else {
		    $ICSource = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($InstChoco).FileVersion
		    $ICDest = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$SavePath\InstChoco.exe").FileVersion
		    if ($ICSource -ne $ICDest)
		       {
		        Copy-Item $InstChoco $SavePath -force | out-null
		        Write-Host "  * $SavePath\InstChoco.exe COPIED!" -ForegroundColor green
			   }
	   }
    }
  }

# Write out the saved list of ALL installed programs to AllProgramsList.txt
Function Write-AllProgramsList{
    Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher | Format-Table >"$SavePath\$AllProgramsListFile"
    Write-Host "  * $SavePath\$AllProgramsListFile SAVED!" -ForegroundColor green
# 2nd copy in format AllProgramsList_date.txt if AppendDate is set to true	
    if ($AppendDate -eq "true"){
	    $AllProgramsListFileArchival = $AllProgramsListFile.Replace(".txt","")+"_$Date.txt"
        Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher | Format-Table >$SavePath\$AllProgramsListFileArchival
        Write-Host "  * $SavePath\$AllProgramsListFileArchival SAVED!" -ForegroundColor green
       }
}  
  
# Write out the saved list of packages to packages.config
Function Write-PackagesConfig{ 
    Check-SaveLocation
    Write-Output "<?xml version=`"1.0`" encoding=`"utf-8`"?>" >"$SavePath\$PackagesListFile"
    Write-Output "<packages>" >>"$SavePath\$PackagesListFile"
	if ($SaveVersions -match "True")
	   {
        choco list -lo -r -y | % { "   <package id=`"$($_.SubString(0, $_.IndexOf("|")))`" version=`"$($_.SubString($_.IndexOf("|") + 1))`" />" }>>"$SavePath\$PackagesListFile"
	   } else {
         choco list -lo -r -y | % { "   <package id=`"$($_.SubString(0, $_.IndexOf("|")))`" />" }>>"$SavePath\$PackagesListFile"
		}
    Write-Output "</packages>" >>"$SavePath\$PackagesListFile"
	Write-Host "  * $SavePath\$PackagesListFile SAVED!" -ForegroundColor green

# 2nd copy in format packages.config_date.config if AppendDate is set to true	
	if ($AppendDate -eq "true"){
	    Write-Output "<?xml version=`"1.0`" encoding=`"utf-8`"?>" >"$SavePath\$PackagesListArchival"
        Write-Output "<packages>" >>"$SavePath\$PackagesListArchival"
	    if ($SaveVersions -match "True")
	       {
            choco list -lo -r -y | % { "   <package id=`"$($_.SubString(0, $_.IndexOf("|")))`" version=`"$($_.SubString($_.IndexOf("|") + 1))`" />" }>>"$SavePath\$PackagesListArchival"
	       } else {
             choco list -lo -r -y | % { "   <package id=`"$($_.SubString(0, $_.IndexOf("|")))`" />" }>>"$SavePath\$PackagesListArchival"
		    }
        Write-Output "</packages>" >>"$SavePath\$PackagesListArchival"
	    Write-Host "  * $SavePath\$PackagesListArchival SAVED!" -ForegroundColor green 
    }
	Check-PPConfig
	Check-InstChoco
	if ($SaveAllProgramsList -eq "true"){Write-AllProgramsList}
}

Write-Host choco-package-list-backup.ps1 v$CPLBver - backup Chocolatey package list locally and to the cloud -ForegroundColor white
Write-Host "Copyleft 2018 Bill Curran (bcurran3@yahoo.com) - free for personal and commercial use" -ForegroundColor white
Write-Host "Choco Package List Backup Summary:" -ForegroundColor magenta

# Backup Chocolatey package names to packages.config file in custom defined path you set as CustomPath in XLM config file
if ($UseCustomPath -match "True" -and (Test-Path $CustomPath))
   {
    $SavePath   = "$CustomPath\$SaveFolderName"
    Write-PackagesConfig
   }
	
# Backup Chocolatey package names on local computer to packages.config file in the Documents folder
$DocumentsFolder = [Environment]::GetFolderPath("MyDocuments")
if ($UseDocuments -match "True" -and (Test-Path $DocumentsFolder))
   {
    $SavePath   = "$DocumentsFolder\$SaveFolderName"
    Write-PackagesConfig
   }
   
# Backup Chocolatey package names on local computer to packages.config file in Box (Sync) directory if it exists
if ($UseBox -match "True" -and (Test-Path "$Env:USERPROFILE\Box Sync"))
   {
    $SavePath = "$Env:USERPROFILE\Box Sync\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }    
   
# Check for Dropbox personal and business paths (Thanks ebbek!)
if (Test-Path $Env:AppData\Dropbox\info.json)
{
    $DropboxPersonal = ((get-content $Env:AppData\Dropbox\info.json) -join '`n' | ConvertFrom-json).personal.path
    $DropboxBusiness = ((get-content $Env:AppData\Dropbox\info.json) -join '`n' | ConvertFrom-json).business.path
}
elseif (Test-Path $Env:LocalAppData\Dropbox\info.json)
{
    $DropboxPersonal = ((get-content $Env:LocalAppData\Dropbox\info.json) -join '`n' | ConvertFrom-json).personal.path
    $DropboxBusiness = ((get-content $Env:LocalAppData\Dropbox\info.json) -join '`n' | ConvertFrom-json).business.path
}

# Backup Chocolatey package names on local computer to packages.config file in Personal Dropbox directory if it exists
if ($UseDropbox -match "True" -and ($DropboxPersonal) -and (Test-Path $DropboxPersonal))
   {
    $SavePath = "$DropboxPersonal\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }
   
# Backup Chocolatey package names on local computer to packages.config file in Business Dropbox directory if it exists
if ($UseDropbox -match "True" -and ($DropboxBusiness) -and (Test-Path $DropboxBusiness))
   {
    $SavePath = "$DropboxBusiness\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }
   
# Backup Chocolatey package names on local computer to packages.config file in Google Drive/Backup and Sync directory if it exists
if ($UseGoogleDrive -match "True" -and (Test-Path "$Env:USERPROFILE\Google Drive"))   
   {
    $SavePath = "$Env:USERPROFILE\Google Drive\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }
   
# Backup Chocolatey package names on local computer to packages.config file in Google Drive FS "My Drive" directory if it exists (Thanks ebbek!)
$GFSInstalled=(test-path -path HKCU:Software\Google\DriveFS\Share)
if ($GFSInstalled)
   {
    $GoogleFSmountpoint = (Get-ItemProperty -path Registry::HKEY_CURRENT_USER\Software\Google\DriveFS\Share).MountPoint
    if ($UseGoogleDrive -match "True" -and ($GoogleFSmountpoint) -and (Test-Path "${GoogleFSmountpoint}:\My Drive"))
       {
        $SavePath = "${GoogleFSmountpoint}:\My Drive\$SaveFolderName\$Env:ComputerName"
        Write-PackagesConfig
       }
	}
   
# Backup Chocolatey package names on local computer to packages.config file on your HOMESHARE directory if it exists
if ($env:HOMESHARE) {$ExistHomeShare="True"} else {$ExistHomeShare="False"}
if ($UseHomeShare -match "True" -and $ExistHomeShare -match "True")   
   {
    $SavePath = "$Env:HOMESHARE\$SaveFolderName\$Env:ComputerName"   
    Write-PackagesConfig
   }      

# Backup Chocolatey package names on local computer to packages.config file in iCloudDrive directory if it exists
if ($iCloudDrive -match "True" -and (Test-Path $Env:USERPROFILE\iCloudDrive))
   {
    $SavePath = "$Env:USERPROFILE\iCloudDrive\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }    
   
# Backup Chocolatey package names on local computer to packages.config file in Nextcloud directory if it exists
if ($UseNextcloud -match "True" -and (Test-Path $Env:USERPROFILE\Nextcloud))
   {
    $SavePath = "$Env:USERPROFILE\Nextcloud\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   } 
   
# Backup Chocolatey package names on local computer to packages.config file in OneDrive directory if it exists
if ($env:OneDrive) {$OneDriveExists="True"} else {$OneDriveExists="False"}
if ($UseOneDrive -match "True" -and ($OneDriveExists -match "True"))
   {
    $SavePath = "$Env:OneDrive\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }      

# Backup Chocolatey package names on local computer to packages.config file in ownCloud directory if it exists
if ($UseownCloud -match "True" -and (Test-Path "$Env:USERPROFILE\ownCloud"))
   {
    $SavePath = "$Env:USERPROFILE\ownCloud\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }
   
# Backup Chocolatey package names on local computer to packages.config file in Netgear ReadyCLOUD directory if it exists
if ($UseReadyCLOUD -match "True" -and (Test-Path $Env:USERPROFILE\ReadyCLOUD))
   {
    $SavePath = "$Env:USERPROFILE\ReadyCLOUD\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }

  
# Backup Chocolatey package names on local computer to packages.config file in Resilio Sync directory if it exists
if ($UseResilioSync -match "True" -and (Test-Path "$Env:USERPROFILE\Resilio Sync"))
   {
    $SavePath = "$Env:USERPROFILE\Resilio Sync\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }   

# Backup Chocolatey package names on local computer to packages.config file in Seafile directory if it exists
if ($UseSeafile -match "True" -and (Test-Path $Env:USERPROFILE\Documents\Seafile))
   {
    $SavePath = "$Env:USERPROFILE\Seafile\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }
   
# Backup Chocolatey package names on local computer to packages.config file in TonidoSync directory if it exists
if ($UseTonidoSync -match "True" -and (Test-Path $Env:USERPROFILE\Documents\TonidoSync))
   {
    $SavePath = "$Env:USERPROFILE\Documents\TonidoSync\$SaveFolderName\$Env:ComputerName"
    Write-PackagesConfig
   }

Write-Host To re-install your Chocolatey packages: -ForegroundColor magenta 
If (Test-Path "$env:ChocolateyInstall\lib\instchoco"){
     Write-Host "Run CINST PACKAGES.CONFIG -Y or INSTCHOCO -Y" -ForegroundColor magenta
   } else {
     Write-Host "Run CINST PACKAGES.CONFIG -Y or get InstChoco and let it do it for you! - https://chocolatey.org/packages/InstChoco" -ForegroundColor magenta 
   }
Write-Host "Found choco-package-list-backup.ps1 useful?" -ForegroundColor white
Write-Host "Buy me a beer at https://www.paypal.me/bcurran3donations" -ForegroundColor white
Write-Host "Become a patron at https://www.patreon.com/bcurran3" -ForegroundColor white
Start-Sleep -s 10


