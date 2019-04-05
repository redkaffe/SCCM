<#
    Script to match the proper Package (containing the drivers) for the Deployed Computer Model
 
    Generate the Packages.xml file:     Get-WmiObject -class sms_package -Namespace root\sms\site_PS1 | Select-Object Name, PackageID | export-clixml -path 'E:\SRC\OSD\OSD-Get-DynamicPackage\packages.xml' -force 
#>

function Get-DynamicPackage
{
    $PackageXMLLibrary = ".\packages.xml"
     Write-Output "PackageXMLLibrary = $PackageXMLLibrary" 

    
	#interesting properties pkgsourcepath, Description, ISVData, ISVString, Manufacturer, MifFileName, Name, MifPublisher, MIFVersion, Name, PackageID, ShareName, Version
    [xml]$Packages = Get-Content -Path $PackageXMLLibrary
    
    
    
    #Defines Match property
    $MatchProperty = 'Name'
    Write-Output "MatchProperty = $MatchProperty"
    #get the Friendly name of Computer Model for $ModelName variable
    switch((Get-WmiObject -Class win32_computersystem).Manufacturer){
    "HP" {$ModelName = (Get-WmiObject -Class win32_computersystem).Model; break}
    "Hewlett Packard" {$ModelName = (Get-WmiObject -Class win32_computersystem).Model; break}
    "Lenovo" {$ModelName = (Get-WmiObject -Class win32_computersystemProduct).Version; break}
    "Dell" {$ModelName = (Get-WmiObject -Class win32_computersystem).Model; break}
    default {$ModelName = (Get-WmiObject -Class win32_computersystem).Model; break}
    }

    Write-Output "ModelName = $ModelName"
    #Define XML file for model/package matching
    #$PackageXMLLibrary = ".\packages.xml"


    #environment variable call for task sequence only
    try
    {
      $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
      $tsenvInitialized = $true
	  $LogPath = $tsenv.Value("_SMSTSLogPath")
    Write-Output "LogPath = $LogPath"
	Write-Output "Model Name = $ModelName" | Out-File -FilePath "$LogPath\Get-DynamicPackage.log" -Encoding "Default" -Append
    }
    catch
    {
      Write-Host -Object 'Not executing in a tasksequence'
	  Write-Output "Not executing in a tasksequence" | Out-File -FilePath "$_SMSTSLogPath\Get-DynamicPackage.log" -Encoding "Default" -Append
	  Write-Output "Model Name = $ModelName" | Out-File -FilePath "$LogPath\Get-DynamicPackage.log" -Encoding "Default" -Append
      $tsenvInitialized = $false
    }
    if ($OSVersion -eq "")
      {
        $PackageID = (Import-Clixml $PackageXMLLibrary | ? {$_.$MatchProperty.Contains($ModelName)}).PackageID
        Write-Output "PackageID = $PackageID"
		Write-Output "PackageID = $PackageID" | Out-File -FilePath "$LogPath\Get-DynamicPackage.log" -Encoding "Default" -Append
          if ($tsenvInitialized)
          {
            $tsenv.Value('OSDDownloadDownloadPackages') = $PackageID
          }
      }
      else
      {
        $PackageID = (Import-Clixml $PackageXMLLibrary | ? {$_.$MatchProperty.Contains($ModelName) -and $_.Version -eq $OSVersion}).PackageID
      Write-Output "PackageIDOSV = $PackageID"
          if ($tsenvInitialized)
          {
            $tsenv.Value('OSDDownloadDownloadPackages') = $PackageID
			Write-Output "PackageID = $PackageID"  | Out-File -FilePath "$LogPath\Get-DynamicPackage.log" -Encoding "Default" -Append
            Write-Output "PackageID = $PackageID" 
          }
      }
  }
Get-DynamicPackage -MatchProperty $MatchProperty -ModelName $ModelName -PackageXMLLibrary $PackageXMLLibrary
