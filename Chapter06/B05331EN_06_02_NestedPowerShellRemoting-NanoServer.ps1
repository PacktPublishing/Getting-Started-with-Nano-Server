# Nested PowerShell Remoting
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 17, 2017
# Requires PowerShell Version 5.0 or above
# Version 2.0

#regionVariables

$NanoSRV = 'NANOSRV-HV01' #Nano Server name or IP address
$DomainCred   = Get-Credential 'Demo\SuperNano'
$VMLocalCred  = Get-Credential '~\Administrator'
$Session = New-PSSession -ComputerName $NanoSRV -Credential $DomainCred

#endregion

Invoke-Command -Session $Session -ScriptBlock {
                param ($VMLocalCred)
                Get-VM
                Invoke-Command -VMName (Get-VM).Name -Credential $VMLocalCred -ScriptBlock {
                                hostname
                                Tzutil /g
                }
} -ArgumentList $VMLocalCred
