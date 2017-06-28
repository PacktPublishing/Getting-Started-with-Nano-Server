# Build Windows Server 2016 Nano Server Container Host
# Create a virtual hard disk for a virtual machine
# Windows Server Containers
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 05, 2017
# Version 3.0
# Note: Chapter 8

#region variables
$ComputerName = "NANOVM-CRHOST"
# Staging path for new Nano image
$StagingPath  = "C:\"
# Path to Windows Server 2016 ISO file
$MediaPath = "H:\"
$Path      = Join-Path -Path $StagingPath -ChildPath NanoServer
$Password  = Read-Host -Prompt 'Please specify local Administrator password' -AsSecureString
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
  'C:\NanoServer\Updates\Servicing stack update\Windows10.0-KB4013418-x64.msu'
  'C:\NanoServer\Updates\Cumulative Update\Windows10.0-KB4013429-x64.msu'
)

$NanoServerImageParameters = @{

  ComputerName = $ComputerName
  MediaPath = $MediaPath
  BasePath = (Join-Path -Path $Path -ChildPath $ComputerName)
  # .vhd for BIOS and .vhdx for UEFI system
  TargetPath = Join-Path -Path $Path -ChildPath ($ComputerName + '.vhdx' )
  AdministratorPassword = $Password
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