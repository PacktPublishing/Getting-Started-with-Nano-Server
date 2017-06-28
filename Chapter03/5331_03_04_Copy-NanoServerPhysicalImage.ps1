# Copy Nano Server VHD to Physical Computer
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - January 18, 2017
# Version 2.0

$ip = "172.16.20.120"
$s = New-PSSession -ComputerName $ip -Credential ~\Administrator
Invoke-Command -Session $s -ScriptBlock {mkdir c:\Nano}
Copy-Item -ToSession $s -Path .\NanoServer01.vhdx -Destination c:\Nano