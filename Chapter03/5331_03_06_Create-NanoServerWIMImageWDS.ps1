# Create Nano Server VHD for WDS deployment
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 18, 2017
# Version 2.0
# For UEFI secureboot support add -package Microsoft-NanoServer-SecureStartup-Package

# Import NanoServerImageGenerator.psd1 PowerShell module
Import-Module "C:\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psd1" -Verbose

# Enter Administrator Password
$Password = Read-Host -Prompt "Please specify local Administrator password" -AsSecureString

# Servicing Update Packages
$ServicingPackage = @(
        "C:\NanoServer\Updates\Windows10.0-KB3199986-x64.cab"
        "C:\NanoServer\Updates\Windows10.0-KB3213986-x64.cab"
         )

# Create New Nano Server Image
New-NanoServerImage -BasePath C:\NanoServer\ `
	            -TargetPath C:\NanoServer\NANO-HV01.wim `
                    -ComputerName "NANO-HV01" `
                    -AdministratorPassword $Password `
                    -DeploymentType Host `
                    -Edition Datacenter `
                    -OEMDrivers `
                    -DriverPath C:\NanoServer\HPE-Drivers `
                    -Compute `
                    -Clustering `
                    -EnableRemoteManagementPort `
                    -EnableEMS `
                    -ServicingPackagePath $ServicingPackage `
                    -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"')

# Apply the unattend.xml file by editing the offline WIM image as follows:
Edit-NanoServerImage -BasePath c:\NanoServer\ -TargetPath c:\NanoServer\NANO-HV01.wim -UnattendPath C:\NanoServer\Unattend.xml