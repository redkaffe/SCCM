#script de lancement RemoteViewer et création des racourcis
#Pierre JOUBERT - RED KAFFE, SARL - v1.0 17.01.2016
#please improve and share back via Technet Gallery
#www.redkaffe.com - @red_kaffe - pierre@redkaffe.com
#start RemoteViewer and create shortcut for remoteViewer
#on a network share with SERIAL/PC Name to ID the client
#Change UNC path and account on line 12
#And serial/PcName/MDT version for shortcut on lines 37/38
#----NO WARRANTy  -  USE AT YOUR OWN RISK ----#

#1 - Map network drive
    net use J: "\\Server\DartShare" /user:LAB\deploy_account P@ssword

#2 - Test remoteDart and launch it 
    Test-Path %windir%\system32\RemoteRecovery.exe
    cmd /C start %windir%\system32\RemoteRecovery.exe -nomessage


#3 - Get-serial as string
    $serial=  gwmi win32_bios | Select –ExpandProperty SerialNumber

#4 - Get inv32.xl, then parse it to build shortcut

    $configxml = ("X:\sms\bin\x64\inv32.xml")
    [xml]$MyConfigFile = Get-Content ($configxml)

    $ticket = $MyConfigFile.E.A.ID
     #IPV6/IPV4 1 for iPv4 & 0 for Ipv6 (2 lines in each XML)
    $ip = $MyConfigFile.E.C.T.L.N[1] 
    $port = $MyConfigFile.E.C.T.L.P[1]


            #Builds the shortcut
            #Change to fit your needs (dart version, here v10) and share
            #And choose between SERIAL or COMPUTERNAME
            #$DestinationPath = "J:\Remote_"+$Env:COMPUTERNAME+"_.lnk"
            $DestinationPath = "J:\Remote_"+$Serial+"_.lnk"
            $SourceExe = "C:\Program Files\Microsoft DaRT\v10\DartRemoteViewer.exe"
            $ArgumentsToSourceExe = """-ticket=$ticket -ipaddress=$ip -port=$port"""

            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($DestinationPath)
            $Shortcut.TargetPath = $SourceExe
            $Shortcut.Arguments = $ArgumentsToSourceExe
            $Shortcut.Save()


#end of script, hope you enjoy it :)