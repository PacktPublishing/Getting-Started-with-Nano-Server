# Build Windows Server 2016 Nano Server
# Create a virtual hard disk for a virtual machine
# Role: DNS Server
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - April 15, 2017
# Version 2.0
# Note: Chapter 10

#region variables
$ComputerName = "NANOVM-DNS"
# Staging path for new Nano image
$StagingPath  = "C:\"
# Path to Windows Server 2016 ISO file
$MediaPath = "H:\"
$Domain = "VIRT.LAB"
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
  'C:\NanoServer\Updates\Cumulative Update\Windows10.0-KB4016635-x64.msu'
 )

$NanoServerImageParameters = @{

  ComputerName = $ComputerName
  MediaPath = $MediaPath
  BasePath = (Join-Path -Path $Path -ChildPath $ComputerName)
  # .vhd for BIOS and .vhdx for UEFI system
  TargetPath = Join-Path -Path $Path -ChildPath ($ComputerName + '.vhdx' )
  AdministratorPassword = $Password
  Package = 'Microsoft-NanoServer-DNS-Package'
  DomainName = $Domain
  ReuseDomainNode = $true
  EnableRemoteManagementPort = $true
  EnableEMS = $true
  DeploymentType = 'Guest'
  Edition = 'Standard'
  MaxSize = 10GB
  InterfaceNameOrIndex = 'Ethernet'
  Ipv4Address = '172.16.20.185'
  Ipv4SubnetMask = '255.255.255.0'
  Ipv4Gateway = '172.16.20.1'
  Ipv4Dns = '172.16.20.9'
  SetupCompleteCommand = ('tzutil.exe /s "W. Europe Standard Time"')
  ServicingPackagePath = $ServicingPackagePath
}

New-NanoServerImage @NanoServerImageParameters

#endregion
