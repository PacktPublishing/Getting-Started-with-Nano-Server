# Create Nano server Virtual Machine
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 20, 2017
# Version 2.0

#region create 5 NANO VIRTUAL MACHINES 
# variables
$vSwitchName01 = "vSwitch"
$InstallRoot = "D:\Hyper-V"

#endregion

1..5 | ForEach-Object {
New-VHD -Path ($InstallRoot + "\NANOVM-OM0$_\NanoServer_D.vhdx") -SizeBytes 50GB -Dynamic
New-VM -VHDPath ($InstallRoot + "\NANOVM-OM0$_\NANOVM-OM0$_.vhdx") -Generation 2 -MemoryStartupBytes 4GB -Name NANOVM-OM0$_ -Path $InstallRoot -SwitchName $vSwitchName01

Set-VMProcessor -VMName NANOVM-OM0$_ -Count 4
Set-VM -VMName NANOVM-OM0$_ -AutomaticStopAction ShutDown -AutomaticStartAction StartIfRunning
Enable-VMIntegrationService NANOVM-OM0$_ -Name "Guest Service Interface"

Rename-VMNetworkAdapter -VMName NANOVM-OM0$_ -NewName "MGMT"
Set-VMNetworkAdapter    -VMName NANOVM-OM0$_ -Name "MGMT" -DeviceNaming On

Add-VMScsiController -VMName NANOVM-OM0$_
Add-VMHardDiskDrive  -VMName NANOVM-OM0$_ -ControllerType SCSI -ControllerNumber 1 -ControllerLocation 0 -Path ($InstallRoot + "\NANOVM-OM0$_\NanoServer_D.vhdx")

Start-VM -Name NANOVM-OM0$_ | Out-Null
}