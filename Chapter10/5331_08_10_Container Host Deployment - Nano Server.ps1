# Windwos Server Container host deployment - Nano Server
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - March 11, 2017
# Version 2.0
# Note: Chapter 8

Get-Item WSMan:\localhost\Client\TrustedHosts | Select-Object value

Set-Item WSMan:\localhost\Client\TrustedHosts "172.16.20.*" -Force

$NanoIP = "172.16.20.157"
$NanoCred = Get-Credential ~\Administrator

Test-WSMan -ComputerName $NanoIP
Test-WSMan -ComputerName $NanoIP -Credential $NanoCred -Authentication Negotiate

$NanoIP = "172.16.20.177"
$NanoCred = Get-Credential ~\Administrator
$Session = New-PSSession -ComputerName $NanoIP -Credential $NanoCred

$NanoIP = "172.16.20.156"
$NanoCred = Get-Credential ~\Administrator
$Session = New-PSSession -ComputerName $NanoIP -Credential $NanoCred
$Session | Enter-PSSession
cd /

New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name WindowsUpdate
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -PropertyType String -Value "http://10.1.1.13:8530"
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name WUStatusServer -PropertyType String -Value "http://10.1.1.13:8530"

New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name AU
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name UseWUServer -PropertyType DWord -Value "1"
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name AUOptions -PropertyType DWord -Value "3"

Get-ChildItem -Path Registry::HKLM\Software\Policies\Microsoft\Windows\ -Recurse |  Where-Object {$_.Name -match "WindowsUpdate"}

Install-PackageProvider NanoServerPackage
Import-PackageProvider NanoServerPackage
Find-NanoServerPackage -Name *Compute*
Install-NanoServerPackage -Name Microsoft-NanoServer-Defender-Package -Force
Install-NanoServerPackage -Name Microsoft-NanoServer-Compute-Package -Force
Get-Package -ProviderName NanoServerPackage -DisplayCulture | FT -AutoSize
Restart-Computer

Import-Module defender
Get-Command -Module defender

Update-MpSignature -Verbose
Start-mpscan -ScanType FullScan -Verbose

Get-MpComputerStatus | FL AMEngineVersion, AMProductVersion, `
AntispywareEnabled, AntispywareSignatureLastUpdated, `
AntispywareSignatureVersion, AntivirusEnabled, `
AntivirusSignatureLastUpdated, AntivirusSignatureVersion

Update-MpSignature -UpdateSource D:\AVSignatures

New-Alias MpCmd "C:\program files\windows defender\MpCmdRun.exe"
MpCmd -SignatureUpdate -Path D:\AVSignatures

MpCmd -RemoveDefinitions -All
MpCmd -scan -2

Add-MpPreference -ExclusionExtension "*.vhdx","*.vhd"
Add-MpPreference -ExclusionPath "D:\VMs"
Add-MpPreference -ExclusionProcess "Vmms.exe", "Vmwp.exe", "Vmcompute.exe"
Get-MpPreference | FT ExclusionExtension, ExclusionPath, ExclusionProcess -AutoSize

Remove-MpPreference -ExclusionProcess "Vmconnect.exe", "Vmsp.exe"

Get-Disk | Where-Object {$_.PartitionStyle -eq "RAW"} | Initialize-Disk -PassThru | `
New-Partition -DriveLetter D -UseMaximumSize | Format-Volume -AllocationUnitSize 64KB -FileSystem NTFS -NewFileSystemLabel "Container Images" -Confirm:$false

$destinationPath = "D:\AVSignatures"

#region create destination path if does not exist
if (-not (Test-Path -Path $destinationPath)) {

  mkdir -Path $destinationPath

}
#endregion

#region Windows Defender Definitions URL
$x64S1 = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x64"
$x64D1 = $destinationPath + "\mpam-fe.exe"
$x64S2 = "http://go.microsoft.com/fwlink/?LinkId=211054"
$x64D2 = $destinationPath + "\mpam-d.exe"
$x64S3 = "http://go.microsoft.com/fwlink/?LinkID=187316&arch=x64&nri=true"
$x64D3 = $destinationPath + "\nis_full.exe"
#endregion

#region Download Windows Defender Definitions
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($x64S1, $x64D1)
$WebClient.DownloadFile($x64S2, $x64D2)
$WebClient.DownloadFile($x64S3, $x64D3)
#endregion

#To Enable IIS-ApplicationInit
dism /Enable-Feature /online /featurename:IIS-ApplicationInit /all

#To Disable IIS-ApplicationInit
dism /Disable-Feature /online /featurename:IIS-ApplicationInit

Exit-PSSession

Enable-WindowsOptionalFeature -Online -FeatureName DNS-Server-Full-Role -Verbose
Get-Service *dns
Get-Service W3SVC
(Get-Command -Module DnsServer).Count
(Get-Command -Module IISAdministration).Count
Get-Command -Module IISAdministration
Import-Module -Name IISAdministration

New-IISSite -Name NanoBook -BindingInformation "*:80:NanoBook" -PhysicalPath C:\inetpub\wwwroot\NanoBook

Exit-PSSession

Enable-SbecAutoLogger -ComputerName $NanoIP -Credential $NanoCred -Verbose
Enable-SbecBcd -ComputerName $NanoIP -CollectorIp 172.16.20.13 -CollectorPort 50039 -Key e.f.g.h -Credential $NanoCred -Verbose
Restart-Computer -ComputerName $NanoIP -Credential $NanoCred -Force
bcdedit /enum
bcdedit /eventsettings

Install-Module -Name DockerMsftProvider -Repository PSGallery -Force

Get-PackageSource -ProviderName DockerMsftProvider

Install-Package -Name docker -ProviderName DockerMsftProvider

Restart-Computer -Force

docker pull microsoft/nanoserver

docker pull nanoserver/iis

docker search IIS

docker images

# list of running containers
docker ps

# list of containers either running or in stop state
docker ps -a


Get-ContainerNetwork

Stop-Service docker
Get-ContainerNetwork | Remove-ContainerNetwork -Force

"vEthernet (HNS Internal NIC)"

Start-Service docker

# New Firewall Rule Docker daemon
New-NetFirewallRule -DisplayName 'Docker Inbound' -Name "Docker daemon" -Profile Any -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2375 -Description "Inbound rule for Docker daemon to allow the Docker Engine to accept incoming connections over [TCP 2375]."

Set-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv4-In)' -Profile Any -Enabled True -Direction Inbound -Action Allow
Set-NetFirewallRule -DisplayName 'File and Printer Sharing (Echo Request - ICMPv6-In)' -Profile Any -Enabled True -Direction Inbound -Action Allow
Set-NetFirewallRule -DisplayName 'File and Printer Sharing (SMB-In)' -Profile Any -Enabled True -Direction Inbound -Action Allow

New-NetFirewallRule -DisplayName 'SBEC' -Name "SBEC" -Profile Any -Direction Inbound -Action Allow -Protocol TCP -LocalPort 50000 -Description "Inbound rule for SBEC to accept incoming connections over [TCP 50000]."


Get-NetFirewallRule -DisplayName 'Docker Inbound'

New-item -Type File C:\ProgramData\docker\config\daemon.json
Remove-Item -Path C:\ProgramData\docker\config\daemon.json -Force

Add-Content 'C:\programdata\docker\config\daemon.json' '{ "hosts": ["tcp://0.0.0.0:2375", "npipe://"],"fixed-cidr":"172.21.16.0/20","graph": "D:\\ProgramData\\Docker" }'

Add-Content 'C:\programdata\docker\config\daemon.json' '{ "fixed-cidr":"172.21.16.0/20" }'
Add-Content 'C:\programdata\docker\config\daemon.json' '{ "graph": "D:\\ProgramData\\Docker" }'

Cat -Path 'C:\programdata\docker\config\daemon.json'

Restart-Service docker

# Remote (Management System) System
Invoke-WebRequest "https://download.docker.com/components/engine/windows-server/cs-1.12/docker.zip" -OutFile "$env:TEMP\docker.zip" -UseBasicParsing

Expand-Archive -Path "$env:TEMP\docker.zip" -DestinationPath $env:ProgramFiles

# For quick use, does not require shell to be restarted.
$env:path += ";c:\program files\docker"
cd "c:\program files\docker"

# For persistent use, will apply even after a reboot.
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine)

$env:DOCKER_HOST = "tcp://172.16.20.185:2375"

docker -H tcp://172.16.20.185:2375 run -it microsoft/nanoserver cmd

# Create a container in interactive mode
docker run -it microsoft/nanoserver cmd

docker run -it -p 8082:80 microsoft/nanoserver cmd

docker search iis

docker pull microsoft/iis

docker pull cobra300/nano-iis

docker images

docker images --no-trunc


docker run -dt -p 8082:80 --isolation=hyperv microsoft/iis

docker run -dt -p 8083:80 --isolation=hyperv microsoft/iis

docker run -dt -p 8084:80 microsoft/iis

docker run -dt -p 8085:80 cobra300/nano-iis

docker run -it -v d:\Container-Data:c:\data microsoft/nanoserver powershell

docker ps -a

docker ps

docker ps -a --filter "isolation=hyperv"

docker ps --filter "isolation=process"

docker ps --filter "isolation=process"
docker stop f654227ca0ac
docker commit --author "Charbel Nemnom" f654227ca0ac nano-hvctn:CN
docker images
docker run --name convert_wsctn_hvctn -dt -p 8085:80 --isolation=hyperv nano-hvctn:CN
docker ps --filter "isolation=hyperv"

New-Item -Path D:\ -Name "Container-Data" -ItemType Directory -Verbose

New-Item -Path D:\Container-Data\ -Name "database.txt" -ItemType File

docker exec -it 37cd2ca12e78 ipconfig

docker kill

# Install a Software on a container
apt-get install vim

# Exist out of a container
# exit

# Create an image base on a container that you installed the software
docker commit "Container ID" name

# Spin up two containers
docker-compose up -d



Get-Module -ListAvailable
Get-Command -Module Microsoft.PowerShell.LocalAccounts | Sort-Object Noun | Format-Table -GroupBy Noun
Get-Command -Module Containers
Get-Command -CommandType Cmdlet,Function | Measure-Command

mkdir C:\DemoShare -Force

Exit-PSSession

$CS = New-CimSession -ComputerName $NanoIP -Credential $NanoCred
$CS

Get-NetFirewallRule -CimSession $CS -Name *winrm-http* | Format-Table Name, Enabled, Action, Direction -AutoSize

# SMB Share module doesn't exist on Nano Server
Invoke-Command -Session $Session -ScriptBlock {Get-Module SMBShare -ListAvailable}
Get-SmbShare -CimSession $cs
New-SmbShare -CimSession $cs

Expand.exe .\Windows10.0-KB4013418-x64.msu -F:* .\

#Update the IP address according to your environment.
$NanoIP = "172.16.20.185"
$Session = New-PSSession -ComputerName $NanoIP -Credential Administrator
Copy-Item -ToSession $Session -Path C:\NanoServer\Updates\ -Destination C:\ -Recurse -Force
$Session | Enter-PSSession
Set-Location C:\

#Apply the servicing stack update first and then restart
Add-WindowsPackage -Online -PackagePath 'C:\Updates\Servicing Stack Update\Windows10.0-KB4013418-x64.cab'
Restart-Computer; exit

#After restarting, apply the cumulative update and then restart
$Session = New-PSSession -ComputerName $NanoIP -Credential Administrator
$Session | Enter-PSSession
Set-Location C:\
Add-WindowsPackage -Online -PackagePath 'C:\Updates\Cumulative Update\Windows10.0-KB4023680-x64.cab'
Restart-Computer; exit

#Update the IP address according to your environment.
$NanoIP = "172.16.20.185"
$Session = New-PSSession -ComputerName $NanoIP -Credential Administrator
$Session | Enter-PSSession
Set-Location C:\

$ci = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$result = $ci | Invoke-CimMethod -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=0";OnlineScan=$true}
$result.Updates