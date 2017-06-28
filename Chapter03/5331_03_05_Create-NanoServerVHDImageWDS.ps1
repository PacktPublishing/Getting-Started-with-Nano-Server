# Create Nano Server VHD for WDS deployment
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 18, 2017
# Version 2.0
# Note: If the physical server uses UEFI to boot,
#       then make sure to change NANO-HV01.vhd to NANO-HV01.vhdx

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
	            -TargetPath C:\NanoServer\NANO-HV01.vhd `
                    -ComputerName "NANO-HV01" `
                    -AdministratorPassword $Password `
                    -DeploymentType Host `
                    -Edition Datacenter `
                    -DomainName VIRT.LAB `
	            -OEMDrivers `
                    -DriverPath C:\NanoServer\HPE-Drivers `
                    -Compute `
                    -Clustering `
                    -Storage `
	            -EnableRemoteManagementPort `
                    -ServicingPackagePath $ServicingPackage `
                    -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"')