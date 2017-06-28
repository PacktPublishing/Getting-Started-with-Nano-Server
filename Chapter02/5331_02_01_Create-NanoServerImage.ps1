# Build Windows Server 2016 Nano Server Image
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 14, 2017
# Version 2.0

# Windows Server 2016 ISO Image Media
$ServerISO = "C:\WindowsServer2016.ISO"

# Mount the ISO Image
Mount-DiskImage $ServerISO

# Get the Drive Letter of the disk ISO image
$DVDDriveLetter = (Get-DiskImage $ServerISO | Get-Volume).DriveLetter

# Import NanoServerImageGenerator.psd1 PowerShell module
Import-Module "C:\NanoServer\NanoServerImageGenerator\NanoServerImageGenerator.psd1" -Verbose

Set-Location C:\NanoServer

# Enter Administrator Password
$Password = Read-Host -Prompt "Please specify local Administrator password" -AsSecureString

# Create New Nano Server Image
New-NanoServerImage -MediaPath "$($DVDDriveLetter):" `
	                -BasePath C:\NanoServer\ `
	                -TargetPath C:\NanoServer\NanoServer01.vhdx `
                    -DeploymentType Guest `
                    -Edition Datacenter `
                    -ComputerName "NANO-01" `
                    -AdministratorPassword $Password `
                    -InterfaceNameOrIndex Ethernet `
	                -Ipv4Address 192.168.1.10 `
	                -Ipv4SubnetMask 255.255.255.0 `
                    -Ipv4Dns 192.168.1.9 `
	                -Ipv4Gateway 192.168.1.1 `
	                -EnableRemoteManagementPort `
                    -Verbose

# Dismount Windows Server 2016 ISO Image
Dismount-DiskImage $ServerISO