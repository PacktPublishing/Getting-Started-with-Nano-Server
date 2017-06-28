# Build Windows Server 2016 Nano Server Image
# Create a Nano server VM Image with DSC Package
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 20, 2017
# Requires PowerShell Version 5.0 or above
# Version 2.0

#region variables
# Staging path for new Nano image
$StagingPath  = 'C:\'
# Path to Windows Server 2016 ISO file
$MediaPath    = 'H:\'
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

1.. 5 | ForEach-Object {
  $ComputerName = "NANOVM-OM0$_"
  $NanoServerImageParameters = @{

    ComputerName = $ComputerName
    MediaPath = $MediaPath
    BasePath = (Join-Path -Path $Path -ChildPath $ComputerName)
    # .vhd for Gen1 VM and .vhdx for Gen2 VM
    TargetPath = Join-Path -Path $Path -ChildPath ($ComputerName + '.vhdx' )
    AdministratorPassword = $Password
    Containers = $true
    Package = 'Microsoft-NanoServer-DSC-Package'
    EnableRemoteManagementPort = $true
    DeploymentType = 'Guest'
    Edition = 'Standard'
    ServicingPackagePath = $ServicingPackagePath
  }

  New-NanoServerImage @NanoServerImageParameters

}

#endregion