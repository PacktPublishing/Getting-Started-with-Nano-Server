# Create Nano server Virtual Machine as a DNS Server
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - April 14, 2017
# Version 2.0
# Note: Chapter 10

# variables
$vSwitchName01 = "Ext_vSwitch01"
$InstallRoot   = "D:\VMs\NANOVM-DNS"
$VMPath   = "D:\VMs"
$VMName = "NANOVM-DNS"
$NanoServerImage = "C:\NanoServer\NANOVM-DNS.vhdx"

#region Create VM directory
if (-not (Test-Path -Path $InstallRoot)) {
   mkdir -Path $VMPath -Name $VMName
}
#endregion

#region copy Nano Image
if (-not (Test-Path -Path ($InstallRoot + "\NANOVM-DNS.vhdx"))) {
Copy-Item -Path $NanoServerImage -Destination $InstallRoot -Force
}
#endregion

#region Create VM
New-VHD -Path   ($InstallRoot + "\NANOVM-DNS_D.vhdx") -SizeBytes 50GB -Dynamic
New-VM -VHDPath ($InstallRoot + "\NANOVM-DNS.vhdx")   -Generation 2 -MemoryStartupBytes 2GB `
       -Name $VMName -Path $InstallRoot -SwitchName $vSwitchName01

Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
Set-VMProcessor -VMName $VMName -Count 2
Set-VM -VMName $VMName -AutomaticStopAction ShutDown -AutomaticStartAction StartIfRunning
Enable-VMIntegrationService $VMName -Name "Guest Service Interface"

Rename-VMNetworkAdapter -VMName $VMName -NewName "vmNIC-MGT"
Set-VMNetworkAdapter    -VMName $VMName -Name    "vmNIC-MGT" -DeviceNaming On

Add-VMScsiController -VMName $VMName
Add-VMHardDiskDrive  -VMName $VMName -ControllerType SCSI -ControllerNumber 1 -ControllerLocation 0 -Path ($InstallRoot + "\NANOVM-DNS_D.vhdx")

Start-VM -Name $VMName | Out-Null

#enregion