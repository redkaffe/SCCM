Get-WmiObject -Class sms_package -Namespace root\sms\site_CAS | Select-Object Name, PackageID | where Name -Like 'Drivers -*' | Export-Clixml -Path '\\ecm.era\pkg_source\OSD\DynamicDriverPackages\OSD-Get-DynamicPackage\Packages.xml' -force

#Import des modules powershell SCCM
$ConfigurationManagerModulePath = 'D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Import-Module  $ConfigurationManagerModulePath -Force		

#Redistribution du package après MAJ du XML
$DriverPackageID = "CAS00567"
$SCCMDriveLetter = "CAS" + ":"
$SCCMDrive = new-psdrive -Name CAS -PSProvider "AdminUI.PS.Provider\CMSite" -Root EFP-CCMCASP-01.ECM.ERA
Set-Location $SCCMDriveLetter
$DriveLocation = (Get-Location).drive.name
Set-Location $SCCMDriveLetter
$SCCMPackage = Get-CMPackage | Where {$_.PackageID -eq $DriverPackageID}
$SCCMPackage | Update-CMDistributionPoint