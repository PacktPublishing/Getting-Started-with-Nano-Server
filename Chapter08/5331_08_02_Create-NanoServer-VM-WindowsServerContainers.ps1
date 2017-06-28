# Create Nano server Virtual Machine as a Container Host
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - March 30, 2017
# Version 2.0
# Note: Chapter 8

# variables
$vSwitchName01 = "Ext_vSwitch01"
$InstallRoot   = "D:\VMs\NANOVM-CRHOST"
$VMName = "NANOVM-CRHOST"
$adminPassword = "P@ssw0rd"
$localCred = new-object -typename System.Management.Automation.PSCredential `
             -argumentlist "Administrator", (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
$IP    = "172.16.20.185"
$GWIP  = "172.16.20.1"
$DNSIP = "172.16.20.9"

# Create VM
New-VHD -Path   ($InstallRoot + "\NANOVM-CRHOST_D.vhdx") -SizeBytes 50GB -Dynamic
New-VM -VHDPath ($InstallRoot + "\NANOVM-CRHOST.vhdx")   -Generation 2 -MemoryStartupBytes 4GB `
       -Name $VMName -Path $InstallRoot -SwitchName $vSwitchName01

Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false
Set-VMProcessor -VMName $VMName -Count 4
Set-VM -VMName $VMName -AutomaticStopAction ShutDown -AutomaticStartAction StartIfRunning
Enable-VMIntegrationService $VMName -Name "Guest Service Interface"

Rename-VMNetworkAdapter -VMName $VMName -NewName "vmNIC-MGT"
Set-VMNetworkAdapter    -VMName $VMName -Name    "vmNIC-MGT" -DeviceNaming On

Add-VMScsiController -VMName $VMName
Add-VMHardDiskDrive  -VMName $VMName -ControllerType SCSI -ControllerNumber 1 -ControllerLocation 0 -Path ($InstallRoot + "\NANOVM-CRHOST_D.vhdx")

Start-VM -Name $VMName | Out-Null

# Wait for VM to respond
Wait-VM -Name $VMName -For Heartbeat

# Set NANO VM IP address statically using PowerShell Direct
Invoke-Command -VMName $VMName -Credential $localCred -ScriptBlock {
  New-NetIPAddress -InterfaceAlias "Ethernet"  -IPAddress $Using:IP -PrefixLength '24' -Type Unicast -DefaultGateway $Using:GWIP
  Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddress $Using:DNSIP

  # Initialize new data drive to store docker images
  Get-Disk | Where-Object {$_.PartitionStyle -eq "RAW"} | Initialize-Disk -PassThru | `
  New-Partition -DriveLetter D -UseMaximumSize | Format-Volume -AllocationUnitSize 64KB -FileSystem NTFS -NewFileSystemLabel "Container Images" -Confirm:$false
}