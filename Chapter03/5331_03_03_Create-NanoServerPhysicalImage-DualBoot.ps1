# Create Nano Server Physical VHD Image
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 16, 2017
# Version 2.0
# Note: If the physical server uses BIOS to boot instead of UEFI,
#       then make sure to change NanoServer01.vhdx to NanoServer01.vhd,
#       and remove "Microsoft-NanoServer-SecureStartup-Package"

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
	            -TargetPath C:\NanoServer\NanoServer01.vhdx `
                    -ComputerName "NANO-HV01" `
                    -AdministratorPassword $Password `
                    -DeploymentType Host `
                    -Edition Datacenter `
                    -OEMDrivers `
                    -DriverPath C:\NanoServer\HPE-Drivers `
                    -Compute `
                    -Clustering `
                    -Storage `
                    -Package Microsoft-NanoServer-SecureStartup-Package `
	            -EnableRemoteManagementPort `
                    -ServicingPackagePath $ServicingPackage `
                    -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"')