# Download and Install xNetworking module from PSGallery
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 20, 2017
# Requires PowerShell Version 5.0 or above
# Version 2.0

#region variables
$LocalPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential ('.\Administrator', $LocalPassword)
#endregion

# Download and Save xNetworking module locally from PSGallery
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Save-Module -Name xNetworking -Path C:\NanoServer

# Copy and install xNetworking module on all Nano Servers
1..5 | ForEach-Object {
       $S1 = New-PSSession -VMName NANOVM-OM0$_ -Credential $LocalCred
       Copy-Item -Path C:\NanoServer\xNetworking -ToSession $S1 -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
       Invoke-Command -Session $S1 -ScriptBlock { Import-Module -Name xNetworking -Verbose }
 }

