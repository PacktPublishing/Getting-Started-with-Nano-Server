# Build Windows Server 2016 Nano Server Image
# Create a virtual hard disk for a physical machine
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 11, 2017
# Version 2.0

#region variables
$ComputerName = 'NANOSRV-HV01'
# Staging path for new Nano image
$StagingPath  = 'C:\'
# Path to Windows Server 2016 ISO file 
$MediaPath    = 'H:\'
$DriverPath = 'C:\NanoServer\HPE-Drivers'                
$Path = Join-Path -Path $StagingPath -ChildPath NanoServer
$Password = Read-Host -Prompt "Please specify local Administrator password" -AsSecureString
#endregion
 
#region Copy source files
if (-not (Test-Path $StagingPath)) {
 
  mkdir $StagingPath
 
}

if (-not (Test-Path $Path)) {
 
  $NanoServerSourcePath = Join-Path -Path $MediaPath -ChildPath NanoServer -Resolve
  Copy-Item -Path $NanoServerSourcePath -Destination $StagingPath -Recurse
} 
#endregion
 
#region Generate Nano Image
Import-Module -Name (Join-Path -Path $Path -ChildPath NanoServerImageGenerator) -Verbose
 
$ServicingPackagePath = @(
  'C:\NanoServer\Updates\Servicing stack update\Windows10.0-kb3211320-x64.msu'
  'C:\NanoServer\Updates\Cumulative Update\Windows10.0-kb4010672-x64.msu'
)
 
$NanoServerImageParameters = @{
 
  ComputerName = $ComputerName
  MediaPath = $MediaPath
  BasePath = (Join-Path -Path $Path -ChildPath $ComputerName)
  # .vhd for BIOS and .vhdx for UEFI system
  TargetPath = Join-Path -Path $Path -ChildPath ($ComputerName + '.vhdx' )
  AdministratorPassword = $Password
  Clustering = $true
  Package = 'Microsoft-NanoServer-Storage-Package','Microsoft-NanoServer-SCVMM-Package','Microsoft-NanoServer-SCVMM-Compute-Package'
  OEMDrivers = $true
  DriverPath = $DriverPath
  EnableRemoteManagementPort = $true
  EnableEMS = $true 
  DeploymentType = 'Host'
  Edition = 'Datacenter'
  ServicingPackagePath = $ServicingPackagePath
}
 
New-NanoServerImage @NanoServerImageParameters

#endregion