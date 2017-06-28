# Deployment from the network using WinPE without WDS
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 06, 2017
# Version 3.0

$WinADK='C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs'
$WinPETemp='D:\TempPE'

Mount-WindowsImage -ImagePath "$WinPETemp\Media\Sources\boot.wim" -Index 1 -Path "$WinPETemp\Mount"

$CABfiles = @("$WinADK\WinPE-WMI.cab","$WinADK\en-us\WinPE-WMI_en-us.cab", `
              "$WinADK\WinPE-NetFX.cab","$WinADK\en-us\WinPE-NetFX_en-us.cab", `
              "$WinADK\WinPE-Scripting.cab","$WinADK\en-us\WinPE-Scripting_en-us.cab", `
              "$WinADK\WinPE-PowerShell.cab","$WinADK\en-us\WinPE-PowerShell_en-us.cab", `
              "$WinADK\WinPE-StorageWMI.cab","$WinADK\en-us\WinPE-StorageWMI_en-us.cab", `
              "$WinADK\WinPE-DismCmdlets.cab","$WinADK\en-us\WinPE-DismCmdlets_en-us.cab")

Foreach ($CABfile in $CABfiles) {
        Add-WindowsPackage -PackagePath "$CABFile" -Path "$WinPeTemp\Mount" -IgnoreCheck
}

Notepad "$WinPETemp\Mount\Windows\System32\Startnet.cmd"

Net use S: \\<IP>\TempPE /User:<XXXXXX> <XXXXXX>
PowerShell "Set-ExecutionPolicy Bypass -Force"
PowerShell ". S:\NanoServerDeployment-WithoutWDS.ps1"
exit

Dismount-WindowsImage -path "$WinPETemp\Mount" -save