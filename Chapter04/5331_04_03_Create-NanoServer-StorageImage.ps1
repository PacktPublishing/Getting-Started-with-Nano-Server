# Build Windows Server 2016 Nano Server Storage Image
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 09, 2017
# Version 1.0

# Import NanoServerImageGenerator.psd1 PowerShell module
Import-Module "C:\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psd1" -Verbose

# Enter Administrator Password
$Password = Read-Host -Prompt "Please specify local Administrator password" -AsSecureString

# Domain Name
$myDomainFQDN = “VIRT.LAB”

# Servicing Update Packages
$ServicingPackage = @(
                     "C:\NanoServer\Updates\Servicing Stack Update\Windows10.0-KB4013418-x64.msu"
                     "C:\NanoServer\Updates\Cumulative Update\Windows10.0-KB4023680-x64.msu"
                     )

# Nano Packages
$NanoPackage = @(
               "Microsoft-NanoServer-DCB-Package"
               "Microsoft-NanoServer-SCVMM-Package"
               "Microsoft-NanoServer-SCVMM-Compute-Package"
                )

1..4 | ForEach-Object {
New-NanoServerImage -BasePath C:\NanoServer\ `
	                -TargetPath C:\NanoServer\NANOS2D-HV0$_.vhdx `
                    -MaxSize 20GB `
                    -DeploymentType Host `
                    -Edition Datacenter `
                    -ComputerName NANOS2D-HV0$_ `
                    -AdministratorPassword $Password `
                    -DomainName $myDomainFQDN `
                    -ReuseDomainNode `
                    -Storage `
                    -Clustering `
                    -Package $NanoPackage `
                    -OEMDrivers `
                    -DriversPath D:\NanoServer\HP-Nano `
                    -EnableRemoteManagementPort `
                    -EnableEMS `
                    -ServicingPackagePath $ServicingPackage `
                    -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"')
}
