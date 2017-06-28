# Build Windows Server 2016 Nano Server Image
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 15, 2017
# Version 2.0

# Windows Server 2016 ISO Image Media
$ServerISO = "C:\NanoServer\WindowsServer2016.ISO"

# Mount the ISO Image
Mount-DiskImage $ServerISO

# Get the Drive Letter of the disk ISO image
$DVDDriveLetter = (Get-DiskImage $ServerISO | Get-Volume).DriveLetter 

# Import NanoServerImageGenerator.psd1 PowerShell module 
Import-Module "C:\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psd1" -Verbose

# Enter Administrator Password
$Password = Read-Host -Prompt "Please specify local Administrator password" -AsSecureString

# Servicing Update Packages
$ServicingPackage = @(  
        "C:\NanoServer\Updates\Windows10.0-KB3199986-x64.cab"
        "C:\NanoServer\Updates\Windows10.0-KB3213986-x64.cab"
         ) 

New-NanoServerImage -MediaPath "$($DVDDriveLetter):" `
	            -BasePath C:\NanoServer\ `
	            -TargetPath C:\NanoServer\NanoServerVM01.vhdx `
                    -MaxSize 20GB `
                    -DeploymentType Guest `
                    -Edition Datacenter `
                    -ComputerName "NANO-VM01" `
                    -AdministratorPassword $Password `
                    -InterfaceNameOrIndex Ethernet `
	            -Ipv4Address 192.168.1.10 `
	            -Ipv4SubnetMask 255.255.255.0 `
                    -Ipv4Dns 192.168.1.9 `
	            -Ipv4Gateway 192.168.1.1 `
	            -EnableRemoteManagementPort `
                    -ServicingPackagePath $ServicingPackage `
                    -SetupCompleteCommand ('tzutil.exe /s "W. Europe Standard Time"')

# Dismount Windows Server 2016 ISO Image
Dismount-DiskImage $ServerISO