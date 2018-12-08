﻿$ErrorActionPreference = 'Stop'
$packageName = 'choco-install-packages-from-web-winconfig'
$pp          = Get-PackageParameters

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ea SilentlyContinue | Out-Null
Remove-Item -Path "HKCR:nupkg_auto_file" -Recurse –Force | Out-Null
Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\" -Name "$env:ChocolateyInstall\bin\cinst.exe" -ea SilentlyContinue | Out-Null
