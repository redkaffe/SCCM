########################################################################
## PEJ - 14-01-2018 - V1 - Script d'import d'Applications SCCM (+DTs) ##
## Ce script parse le répertoire de sources et crée chaque appli avec ##
## les Deployment Types en fonction de l'architecture: x86/x64/Common ##
## Il récupere les infos du MSI et peuple les champs de l'application ##
## Pour les détails: http://www.redkaffe.com - Pierre E. JOUBERT      ##
########################################################################

####################################################################################################
###  C R E D I T S       T O    A L L   M.V.P.s   &     B L O G G E R S   A R O U N D    ! ! !   ###
####################################################################################################
## Ce script s'inspire et utilise des fonctions créées par David O'Brien et Nickolaj Andersen.     #
## visitez leurs sites pour en savoir plus, un gros merci a tous!                                  #
## http://www.scconfigmgr.com/2014/08/22/how-to-get-msi-file-information-with-powershell/          #
## https://david-obrien.net/2013/07/create-new-configmgr-applications-from-script-with-powershell/ #
####################################################################################################

Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1') | Out-Null

# SCCM cmdlets need to be run from the SCCM drive # 
#>>>>>>>>>>>>>>> MODIFY YOUR SITE CODE HERE <<<<<<# 
Set-Location "$("RK1"):" | Out-Null
if (-not (Get-PSDrive -Name "RK1"))
    {
        Write-Error "There was a problem loading the Configuration Manager powershell module and accessing the site's PSDrive."
        exit 1
    }

function Get-MSIinfo {
param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$Path,
 
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage")]
    [string]$Property
)
Process {
    try {
        # Read property from MSI database
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
        $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
        $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
        $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
        $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
 
        # Commit database and close view
        $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
        $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
        $MSIDatabase = $null
        $View = $null
 
        # Return the value
        return $Value
    } 
    catch {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
End {
    # Run garbage collection and release ComObject
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
    [System.GC]::Collect()
}
}


###################################################################
#Define path containing sources of applications to integrate below#
#>>>>>>>>> MODIFY YOUR PATHs HERE (DIR1)   <<<<<<<<<<<<<<<<<<<<<<<#
###################################################################

#this is for the LOCAL loops logic to work once connected to PSD
$SourceApps= "S:\SRC\APPS\Sources_App\"

#this is for the UNC path of the source in the Deployment Type
$UNCPATH = "\\CM01\SRC\APPS\Sources_App\"

###################################################################
#####  Nothing else should need modifications from here ... #######
###################################################################

$Applist = @(Get-ChildItem $SourceApps)

foreach ($App in $Applist){ 

#create application (once only - we will append Deployments types to that application)
write-host $App
$NewApp = New-CMApplication -Name "$($App)" -Description "$($App)" -AutoInstall $true

    $x64AppPath = $SourceApps + $App + "\x64"
        if (Test-Path $x64AppPath"\*.msi") {
        Write-Host $x64AppPath
        $MSISource =  gci ($x64AppPath + "\*.msi")
        Write-host MSISource : $MSISource
        $MSIFile = Split-Path $MSISource -Leaf
        $MSISourceUNC = $UNCPATH + $App + "\x64\" + $MSIFILE
        Write-Host MSISourceUNC : $MSISourceUNC
        $MSIProductCode = Get-MSIInfo -Path $MSISource -property ProductCode 
        $MSIProductName = Get-MSIInfo -Path $MSISource -property ProductName
        $MSIProductVersion = Get-MSIInfo -Path $MSISource -property ProductVersion
        $MSIManufacturer = Get-MSIInfo -Path $MSISource -property Manufacturer
        $MSILanguage = Get-MSIInfo -Path $MSISource -property ProductLanguage
        Write-Host $MSIProductName, $MSIManufacturer, $MSIProductVersion, $MSILanguage, $MSIProductCode
        $DeploymenttypeName = "DT - MSI Based - " + $App + " - x64"
        Write-host $DeploymentTypeName
        Add-CMMsiDeploymentType -ApplicationName $App -DeploymentTypeName $DeploymenttypeName -ContentLocation $MSISourceUNC -Force
        Set-CMApplication -Name "$($App)" -Publisher "$($MSIManufacturer)" -SoftwareVersion "$($MSIProductVersion)"
        }

    $x86AppPath = $SourceApps + $App + "\x86"
        if (Test-Path $x86AppPath"\*.msi") {
        Write-Host $x86AppPath
        $MSISource =  gci ($x86AppPath + "\*.msi")
        Write-host MSISource : $MSISource
        $MSIFile = Split-Path $MSISource -Leaf
        $MSISourceUNC = $UNCPATH + $App + "\x86\" + $MSIFILE
        Write-Host MSISourceUNC : $MSISourceUNC
        $MSIProductCode = Get-MSIInfo -Path $MSISource -property ProductCode 
        $MSIProductName = Get-MSIInfo -Path $MSISource -property ProductName
        $MSIProductVersion = Get-MSIInfo -Path $MSISource -property ProductVersion
        $MSIManufacturer = Get-MSIInfo -Path $MSISource -property Manufacturer
        $MSILanguage = Get-MSIInfo -Path $MSISource -property ProductLanguage
        Write-Host $MSIProductName, $MSIManufacturer, $MSIProductVersion, $MSILanguage, $MSIProductCode
        $DeploymenttypeName = "DT - MSI Based - " + $App + " - x86"
        Write-host $DeploymentTypeName
        Add-CMMsiDeploymentType -ApplicationName $App -DeploymentTypeName $DeploymenttypeName -ContentLocation $MSISourceUNC -Force
        Set-CMApplication -Name "$($App)" -Publisher "$($MSIManufacturer)" -SoftwareVersion "$($MSIProductVersion)"
        }

    $CommonAppPath = $SourceApps + $App
        if (Test-Path $CommonAppPath"\*.msi") {
        Write-Host $CommonAppPath
        $MSISource =  gci ($CommonAppPath + "\*.msi")
        Write-host MSISource : $MSISource
        $MSIFile = Split-Path $MSISource -Leaf
        $MSISourceUNC = $UNCPATH + $App + "\" + $MSIFILE
        Write-Host MSISourceUNC : $MSISourceUNC
        $MSIProductCode = Get-MSIInfo -Path $MSISource -property ProductCode 
        $MSIProductName = Get-MSIInfo -Path $MSISource -property ProductName
        $MSIProductVersion = Get-MSIInfo -Path $MSISource -property ProductVersion
        $MSIManufacturer = Get-MSIInfo -Path $MSISource -property Manufacturer
        $MSILanguage = Get-MSIInfo -Path $MSISource -property ProductLanguage
        Write-Host $MSIProductName, $MSIManufacturer, $MSIProductVersion, $MSILanguage, $MSIProductCode
        $DeploymenttypeName = "DT - MSI Based - " + $App + " - Common"
        Write-host $DeploymentTypeName
        Add-CMMsiDeploymentType -ApplicationName $App -DeploymentTypeName $DeploymenttypeName -ContentLocation $MSISourceUNC -Force
        Set-CMApplication -Name "$($App)" -Publisher "$($MSIManufacturer)" -SoftwareVersion "$($MSIProductVersion)"
        }

}

 Set-Location C:\
