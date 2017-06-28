# Install Nano Server Packages - Online
# NanoServerPackageProvider - PackageManagement (a.k.a OneGet)
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 03, 2017
# Version 3.0

# Variables
$NanoIP = "172.16.19.21"
$Session = New-PSSession -ComputerName $NanoIP -credential "Domain\SuperNano"

#region Install NanoServer Roles and Features
$Session | Enter-PSSession
Set-Location /

# Download Nano Server Package module
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name NanoServerPackage -MinimumVersion 1.0.1.0
Import-PackageProvider NanoServerPackage -Verbose

# Find all available online Nano packages (en-us Language)
Find-Package -ProviderName NanoServerPackage -culture en-us

# Filter SCVMM Packages
Find-Package -ProviderName NanoServerPackage -culture en-us | Where-Object {$_.Name -like "*SCVMM*"}

# Install SCVMM package that depends on other packages with a single command.
# In this case, the dependency packages will be installed as well.
# Microsoft-NanoServer-SCVMM-Package, Microsoft-NanoServer-Compute-Package, Microsoft-NanoServer-SCVMM-Compute-Package
Find-NanoServerPackage *scvmm-compute* | install-package -Force | Format-Table -AutoSize

# Search for all Windows Packages installed on the local machine.
Get-Package -ProviderName NanoServerPackage -DisplayCulture | Format-Table -AutoSize

Restart-Computer

#endregion
