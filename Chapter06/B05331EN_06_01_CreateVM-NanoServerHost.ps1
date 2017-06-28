# Create Virtual Machine on Nano Server Hyper-V Host
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 17, 2017
# Requires PowerShell Version 5.0 or above
# Version 3.0

#region Variables

$NanoSRV = 'NANOSRV-HV01'
$Cred = Get-Credential 'Demo\SuperNano'
$Session = New-PSSession -ComputerName $NanoSRV -Credential $Cred
$CimSesion = New-CimSession -ComputerName $NanoSRV -Credential $Cred
$VMTemplatePath = 'C:\Temp'
$vSwitch = 'Ext_vSwitch'
$VMName = 'DemoVM-0'

#endregion

# Copying VM Template from the management machine to Nano Server
Get-ChildItem -Path $VMTemplatePath -filter *.VHDX -recurse | Copy-Item -ToSession $Session -Destination D:\

1..2 | ForEach-Object {

New-VM -CimSession $CimSesion -Name $VMName$_ -VHDPath "D:\$VMName$_.vhdx" -MemoryStartupBytes 1024GB `
-SwitchName $vSwitch -Generation 2

Start-VM -CimSession $CimSesion -VMName $VMName$_ -Passthru    
 
} 
