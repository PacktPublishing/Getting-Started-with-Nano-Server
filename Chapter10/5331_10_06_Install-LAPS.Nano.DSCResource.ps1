# Download and Install LAPS.Nano.DSC module from PSGallery
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date : May 30, 2017
# Requires PowerShell Version 5.0 or above
# Version 2.0

#region variables
$LocalPassword = ConvertTo-SecureString -String '210sabis+1' -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential ('.\Administrator', $LocalPassword)
#endregion

# Download and Install LAPS.Nano.DSC module locally from PSGallery
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name LAPS.Nano.DSC -Force

# Copy and install LAPS.Nano.DSC module on all Nano Servers
$Source = 'C:\Program Files\WindowsPowerShell\Modules\LAPS.Nano.DSC'
$Destination = 'C:\Program Files\WindowsPowerShell\Modules'
1..5 | ForEach-Object {
       $S1 = New-PSSession -VMName NANOVM-OM0$_ -Credential $LocalCred
       Copy-Item -Path $Source -ToSession $S1 -Destination $Destination -Recurse -Force
       Invoke-Command -Session $S1 -ScriptBlock { Import-Module -Name LAPS.Nano.DSC -Verbose }
 }
