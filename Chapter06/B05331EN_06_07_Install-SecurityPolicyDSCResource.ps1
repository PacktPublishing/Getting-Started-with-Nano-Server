# Download and Install Security Policy DSC resource from PSGallery
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 20, 2017
# Requires PowerShell Version 5.0 or above
# Version 2.0

#region variables
$LocalPassword = ConvertTo-SecureString -String 'P@ssw0rd'  -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential ('.\Administrator', $LocalPassword)
#endregion

# Download and Save Security Policy DSC resource locally from PSGallery
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Save-Module -Name SecurityPolicyDsc, AuditPolicyDsc, GpRegistryPolicy -Path C:\NanoServer

# Copy and install Security Policy DSC resource to all Nano Servers
1..5 | ForEach-Object {
  $S1 = New-PSSession -VMName NANOVM-OM0$_ -Credential $LocalCred
  Copy-Item -Path C:\NanoServer\SecurityPolicyDsc -ToSession $S1 -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
  Copy-Item -Path C:\NanoServer\AuditPolicyDsc    -ToSession $S1 -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
  Copy-Item -Path C:\NanoServer\GpRegistryPolicy  -ToSession $S1 -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Force
  Invoke-Command -Session $S1 -ScriptBlock { Import-Module -Name SecurityPolicyDsc, AuditPolicyDsc, GpRegistryPolicy -Verbose }
}
