# Create Nano Server VM
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 16, 2017
# Version 2.0

# Variables
$vSwitchName01 = "NAT_vSwitch"
$InstallRoot = "C:\NanoServer"
$VMName = "NanoServerVM01"
$NanoServerImage = "C:\NanoServer\NanoServerVM01.vhdx"

# Create a new VHD(X) file
New-VHD -Path ($InstallRoot + "\$VMName\NanoServerVM01_D.vhdx") -SizeBytes 50GB -Dynamic | Out-Null

# Create Nano Server VM
New-VM -VHDPath $NanoServerImage -Generation 2 -MemoryStartupBytes 2GB -Name $VMName -Path $InstallRoot -SwitchName $vSwitchName01 | Out-Null

# Set vCPU count to 4
Set-VMProcessor -VMName $VMName -Count 4

# Set AutomaticStopAction and AutomaticStartAction 
Set-VM -VMName $VMName -AutomaticStopAction ShutDown -AutomaticStartAction StartIfRunning

# Rename vNIC Adapter name to MGMT
Rename-VMNetworkAdapter -VMName $VMName -NewName "MGMT"

# Set vNIC Device Naming to On
Set-VMNetworkAdapter -VMName $VMName -Name "MGMT" -DeviceNaming On

# Add additional SCSI Controller and attach the new VHD(X)
Add-VMScsiController -VMName $VMName
Add-VMHardDiskDrive  -VMName $VMName -ControllerType SCSI -ControllerNumber 1 -ControllerLocation 0 -Path ($InstallRoot + "\$VMName\NanoServerVM01_D.vhdx")

# Start Nano Server VM
Start-VM -Name $VMName | Out-Null
Get-VM -Name $VMName