# Build Windows Server 2016 Nano Server Container Host
# Create a virtual hard disk for a virtual machine
# Windows Server and Hyper-V Containers
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - March 11, 2017
# Version 2.0
# Note: Chapter 8

#region variables
$ComputerName = "NANOVM-CRVHOST"
# Staging path for new Nano image
$StagingPath  = "C:\"
# Path to Windows Server 2016 ISO file 
$MediaPath    = "H:\"
$Path = Join-Path -Path $StagingPath -ChildPath NanoServer
$Password = Read-Host -Prompt 'Please specify local Administrator password' -AsSecureString
#endregion
 
#region Copy source files
if (-not (Test-Path -Path $StagingPath)) {
 
  mkdir -Path $StagingPath
 
}

if (-not (Test-Path -Path $Path)) {
 
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
  Compute = $true
  Containers = $true
  EnableRemoteManagementPort = $true
  EnableEMS = $true 
  DeploymentType = 'Guest'
  Edition = 'Datacenter'
  MaxSize = 40GB
  ServicingPackagePath = $ServicingPackagePath
}
 
New-NanoServerImage @NanoServerImageParameters

#endregion