#PEJ-Script to export drivers from a running windows 10 machine
#Makes a directory named after the WMI result for model request...
if((Get-WmiObject -Class win32_computersystem).Manufacturer="HP"){$ModelName = (Get-WmiObject -Class win32_computersystem).Model}
if((Get-WmiObject -Class win32_computersystem).Manufacturer="Hewlett Packard"){$ModelName = (Get-WmiObject -Class win32_computersystem).Model}
if((Get-WmiObject -Class win32_computersystem).Manufacturer="Lenovo"){$ModelName = (Get-WmiObject -Class win32_computersystemProduct).Version}
if((Get-WmiObject -Class win32_computersystem).Manufacturer="Dell"){$ModelName = (Get-WmiObject -Class win32_computersystem).Model}
Export-WindowsDriver -Destination "C:\Drivers\$ModelName" -Online