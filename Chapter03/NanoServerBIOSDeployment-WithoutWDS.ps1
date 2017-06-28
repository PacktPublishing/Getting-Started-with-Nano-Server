# Automate Nano Server deployment on Physical machine without WDS
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 19, 2017
# Version 2.0
# Note: BIOS Mode
# File: NanoServerBIOSDeployment-WithoutWDS.ps1

# Prepare the physical disk for use. Note the System partition must be marked as Active.
# we also assign a drive letter to the system partition (which we will removed later).
# This allows us to create the disk so that it works for BIOS boot.
 
$script =@"
select disk 0
clean
REM == 1. Windows System partition ===============
create partition primary size=350
active
format quick fs=ntfs label="System"
assign letter="T"
REM == 2. Windows partition ========================
create partition primary
format quick fs=ntfs label="Windows"
assign letter="P"
exit
"@
$script | diskpart

# VHD means BIOS 
Copy S:\NanoServer.VHD P:\NanoServer.VHD
 
# Find out how many physical volumes exist before we do any work with the VHD
[array]$temp = "list volume" | diskpart
$script = @"
select vdisk file=P:\NanoServer.VHD
attach vdisk
exit
"@
$script | diskpart
 
# This determines which volume number the VHD was mounted to. It then assigns the letter V
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