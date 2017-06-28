# Automate Nano Server deployment on Physical machine without WDS
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 19, 2017
# Version 2.0
# Note: UEFI Mode
# File: NanoServerUEFIDeployment-WithoutWDS.ps1

# Prepare the physical disk for use. Note the System partition must be marked as Active.
# we also assign a drive letter to the system partition (which we will removed later).
# This allows us to create the disk so that it works for UEFI boot.
 
$script =@"
select disk 0
clean
Convert GPT
REM == 1. Windows System partition ===============
create partition efi size=100
Format quick fs=fat32 label="System"
assign letter="T"
REM == 2. Windows partition ========================
Create partition msr size=128
Create partition primary
format quick fs=ntfs label="Windows"
assign letter="P"
exit
"@
$script | diskpart

# VHDX means UEFI
Copy S:\NanoServer.VHDX P:\NanoServer.VHDX
 
# Find out how many physical volumes exist before we do any work with the VHDX
[array]$temp = "list volume" | diskpart
$script = @"
select vdisk file=P:\NanoServer.VHDX
attach vdisk
exit
"@
$script | diskpart
 
# This determines which volume number the VHD(X) was mounted to. It then assigns the letter V
$vhdVol      = ($temp.length-12) + 1           # Find volume number
$script = @"
select volume $vhdVol
assign letter=V
exit
"@
$script | diskpart
 
# This bcdboot command write both UEFI and BIOS boot information to the system partition on the physical drive
bcdboot V:\Windows /s T: /f All                 # Write UEFI and BIOS information
 
# Remove the letter T off the system partition of the physical drive.
$script = @"
select disk 0
select partition 1
remove letter=T
exit
"@

# Remove extraneous drive letter
$script | diskpart                      