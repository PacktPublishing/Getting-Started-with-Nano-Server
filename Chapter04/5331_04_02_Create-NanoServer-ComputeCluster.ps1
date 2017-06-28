# Create Nano Server Compute Cluster
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 8, 2017
# Version 2.0

Set-item wsman:localhost\client\trustedhosts -Value "NANOSRV-*" -Force
$NanoServer01 = "NANOSRV-HV01"
$Cred = Get-Credential "~\Administrator"
Enter-PSSession -ComputerName $NanoServer01 -Credential $Cred
Set-Location C:\
Get-ComputerInfo w*x, oss*l

# Credentials & Variables
$Cred = New-object -typename System.Management.Automation.PSCredential -argumentlist ".\Administrator", (ConvertTo-SecureString "PWS" -AsPlainText -Force)
$Nodes = "NANOSRV-HV01", "NANOSRV-HV02", "NANOSRV-HV03", "NANOSRV-HV04"

# Add domain account as local administrator
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Net localgroup Administrators VIRT\ClusterMgmt /add
}

# Set a network QoS policy for SMB
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
New-NetQosPolicy "SMB" -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3
}

# Turn on Flow Control for SMB
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Enable-NetQosFlowControl -Priority 3
}

# Turn off Flow Control
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Disable-NetQosFlowControl -Priority 0,1,2,4,5,6,7
}

# Apply network QoS policy to all NIC RDMA adapters
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Get-NetAdapterQos -Name "*" | Enable-NetAdapterQos
}

# Create a Traffic class and give SMB 50%
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
New-NetQosTrafficClass "SMB" -Priority 3 -BandwidthPercentage 50 -Algorithm ETS
}

# Get physical NIC Adapters names
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Get-NetAdapter | Format-Table Name,InterfaceDescription,Status,LinkSpeed
}

# Create Hyper-V SET virtual switch
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
New-VMSwitch -Name SETvSwitch -NetAdapterName "Ethernet", "Ethernet 2" -EnableEmbeddedTeaming $true
}

# Add host vNICs to the virtual switch
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name SMB_1 -managementOS
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name SMB_2 -managementOS
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name LiveMigration -managementOS
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name Cluster -managementOS
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name Backup -managementOS
}

# Set the IP address for each host vNIC
# Number of Node in the Hyper-V Cluster
$ServerCount = 4
# SMB_1 and SMB_2 Network ID for nodes
$SMB_ID  = "10.11.0."
# Backup Network ID for nodes
$Backup_ID = "10.13.0."
# Start IP address for nodes
$Backup_Network = 11
$SMB_Network    = 11

For ($i = 1; $i -le $ServerCount; $i++) {
$SMB_IP     = $SMB_ID + $SMB_Network
$Backup_IP  = $Backup_ID + $Backup_Network

Invoke-Command -ComputerName "NANOSRV-HV0$i" -Credential $Cred -ScriptBlock {
        Param ($SMB_Network, $SMB_ID, $SMB_IP, $Backup_IP)
        New-NetIPAddress -InterfaceAlias "vEthernet (SMB_1)"  -IPAddress $SMB_IP -PrefixLength “24” -Type Unicast
        $SMB_Network++
        $SMB_IP = ""
        $SMB_IP =  $SMB_ID + $SMB_Network
        New-NetIPAddress -InterfaceAlias "vEthernet (SMB_2)"  -IPAddress $SMB_IP -PrefixLength “24” -Type Unicast
        New-NetIPAddress -InterfaceAlias "vEthernet (Backup)" -IPAddress $Backup_IP -PrefixLength “24” -Type Unicast
        } -ArgumentList $SMB_Network, $SMB_ID, $SMB_IP, $Backup_IP

$Backup_Network++
$SMB_Network++
$SMB_Network++
}

# Disable DNS registration
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Get-DnsClient | Where-Object {$_.InterfaceAlias -ne "vEthernet (SETvSwitch)"} | Set-DNSClient -RegisterThisConnectionsAddress $False
}

# Configure VLANs for host vNICs
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "SMB_1" -VlanId 11 -Access -ManagementOS
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "SMB_2" -VlanId 11 -Access -ManagementOS
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "LiveMigration" -VlanId 12 -Access -ManagementOS
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "Backup" -VlanId 13 -Access -ManagementOS
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "Cluster" -VlanId 14 -Access -ManagementOS
}

# Verify VLANID
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Get-VMNetworkAdapter -SwitchName SETvSwitch -ManagementOS | Get-VMNetworkAdapterVlan
}

# Disable/enable each host vNIC
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Disable-NetAdapter "vEthernet (SMB_1)", "vEthernet (SMB_2)", "vEthernet (LiveMigration)", "vEthernet (Backup)", "vEthernet (Cluster)" -Confirm:$false
Enable-NetAdapter  "vEthernet (SMB_1)", "vEthernet (SMB_2)", "vEthernet (LiveMigration)", "vEthernet (Backup)", "vEthernet (Cluster)"
}

# Enable RDMA on the host vNIC
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Enable-NetAdapterRDMA "vEthernet (SMB_1)","vEthernet (SMB_2)", "vEthernet (LiveMigration)", "vEthernet (Backup)"
}

# Create and configure Nano Hyper-V Cluster
# Validate Cluster
$Nodes = "NANOSRV-HV01", "NANOSRV-HV02", "NANOSRV-HV03", "NANOSRV-HV04"
Test-Cluster -Node $Nodes -Include Inventory,Network,"System Configuration" -Verbose

# Create Cluster
New-Cluster -Name NANOHV-CLU -Node $Nodes -NoStorage -StaticAddress 172.16.20.159/24 -IgnoreNetwork 10.11.0.0/24, 10.13.0.0/24 -Verbose

# Set Cluster Cloud Witness
Set-ClusterQuorum –Cluster NANOHV-CLU –CloudWitness –AccountName nanohvcloudwitness –AccessKey <AccessKey>

# Check Cluster Quorum
Get-ClusterQuorum –Cluster NANOHV-CLU

# Set Cluster Active Memory Dump
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Set-ItemProperty –Path HKLM:\System\CurrentControlSet\Control\CrashControl –Name CrashDumpEnabled –value 1
New-ItemProperty –Path HKLM:\System\CurrentControlSet\Control\CrashControl -Name FilterPages -Value 1
        # CrashDumpEnabled = 7 = Automatic memory dump (default).
        # CrashDumpEnabled = 1 = Complete memory dump.
        # CrashDumpEnabled = 1 and FilterPages = 1 = Active memory dump.
Get-ItemProperty –Path HKLM:\System\CurrentControlSet\Control\CrashControl
}

# Rename Cluster Network names
$Cluster = "NANOHV-CLU"
Get-ClusterNetwork -Cluster $Cluster | Format-List *

# Rename ManagementOS Network and Enable for client and cluster communication
(Get-ClusterNetwork -Cluster $Cluster | Where-Object {$_.Address -eq "172.16.20.0"}).name = "ManagementOS"
(Get-ClusterNetwork -Cluster $Cluster -Name "ManagementOS").Role = 3

# Rename Live Migration Network and Enable for Cluster Communication only
(Get-ClusterNetwork -Cluster $Cluster | Where-Object {$_.Address -eq ""}).name = "LiveMigration"
(Get-ClusterNetwork -Cluster $Cluster -Name "LiveMigration").Role = 1

# Rename SMB Network and Disable for Cluster Communication
(Get-ClusterNetwork -Cluster $Cluster | Where-Object {$_.Address -eq "10.11.0.0"}).name = "SMB_A_B"
(Get-ClusterNetwork -Cluster $Cluster -Name "SMB_A_B").Role = 0

# Rename Backup Network and Disable for Cluster Communication
(Get-ClusterNetwork -Cluster $Cluster | Where-Object {$_.Address -eq "10.13.0.0"}).name = "Backup"
(Get-ClusterNetwork -Cluster $Cluster -Name "Backup").Role = 0

# Configure Live Migration Networks
Get-ClusterResourceType -Cluster $Cluster -Name "Virtual Machine" | Set-ClusterParameter -Name MigrationExcludeNetworks -Value ([String]::Join(";",(Get-ClusterNetwork -Cluster $Cluster | Where-Object {$_.Name -ne "LiveMigration"}).ID))

