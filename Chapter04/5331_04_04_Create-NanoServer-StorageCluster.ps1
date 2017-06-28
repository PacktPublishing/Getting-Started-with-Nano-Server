# Create Nano Server HyperConverged S2D Cluster
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 9, 2017
# Version 2.0


# Credentials & Variables
$Cred = New-object -typename System.Management.Automation.PSCredential -argumentlist ".\Administrator", (ConvertTo-SecureString "PWS" -AsPlainText -Force)
$Nodes = "NANOSRV-S2D01", "NANOSRV-S2D02", "NANOSRV-S2D03", "NANOSRV-S2D04"

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

# Apply network QoS policy to the target RDMA adapters
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Enable-NetAdapterQoS -Name "HPE-640SFP01"
Enable-NetAdapterQoS -Name "HPE-640FLR-SFP01"
}

# Create a Traffic class and give SMB 50%
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
New-NetQosTrafficClass "SMB" -Priority 3 -BandwidthPercentage 50 -Algorithm ETS
}

# Create Hyper-V SET virtual switch
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
New-VMSwitch -Name SETvSwitch -NetAdapterName "HPE-640SFP01", "HPE-640FLR-SFP01" -EnableEmbeddedTeaming $true
}

# Add host vNICs to the virtual switch
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name LiveMigration -managementOS
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name Cluster -managementOS
Add-VMNetworkAdapter -SwitchName SETvSwitch -Name Backup -managementOS
}

# Set the IP address for each host vNIC
# Number of Nodes in S2D hyper-converged Cluster
$ServerCount = 4
# SMB_1 and SMB_2 Network ID for nodes
$SMB_ID    = "10.11.0."
# Backup Network ID for nodes
$Backup_ID = "10.13.0."
# Start IP address for nodes
$Backup_Network = 21
$SMB_Network    = 21

For ($i = 1; $i -le $ServerCount; $i++){
$SMB_IP     = $SMB_ID + $SMB_Network
$Backup_IP  = $Backup_ID + $Backup_Network

Invoke-Command -ComputerName "NANOS2D-HV0$i" -Credential $Cred -ScriptBlock {
        Param ($SMB_Network, $SMB_ID, $SMB_IP, $Backup_IP)

        New-NetIPAddress -InterfaceAlias "HPE-640SFP02"  -IPAddress $SMB_IP -PrefixLength “24” -Type Unicast
        $SMB_Network++
        $SMB_IP = ""
        $SMB_IP =  $SMB_ID + $SMB_Network
        New-NetIPAddress -InterfaceAlias "HPE-640FLR-SFP02"  -IPAddress $SMB_IP -PrefixLength “24” -Type Unicast
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
Set-NetAdapterAdvancedProperty -Name "HPE-640SFP02"     -DisplayName "VLAN ID" -DisplayValue 11
Set-NetAdapterAdvancedProperty -Name "HPE-640FLR-SFP02" -DisplayName "VLAN ID" -DisplayValue 11
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "LiveMigration" -VlanId 12 -Access -ManagementOS
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "Backup"  -VlanId 13 -Access -ManagementOS
Set-VMNetworkAdapterVlan -VMNetworkAdapterName "Cluster" -VlanId 14 -Access -ManagementOS
}

# Verify VLANID
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Get-VMNetworkAdapter -SwitchName SETvSwitch -ManagementOS | Get-VMNetworkAdapterVlan
Get-NetAdapterAdvancedProperty -Name "*SFP02" -DisplayName "VLAN ID" | Select-Object ifAlias, ValueData
}

# Disable/enable each host vNIC
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Disable-NetAdapter "HPE-640SFP02", "HPE-640FLR-SFP02", "vEthernet (LiveMigration)", "vEthernet (Backup)", "vEthernet (Cluster)" -Confirm:$false
Enable-NetAdapter  "HPE-640SFP02", "HPE-640FLR-SFP02", "vEthernet (LiveMigration)", "vEthernet (Backup)", "vEthernet (Cluster)"
}

# Enable RDMA on the host vNIC
Invoke-Command -ComputerName $Nodes -Credential $Cred -ScriptBlock {
Enable-NetAdapterRDMA "HPE-640SFP02","HPE-640FLR-SFP02", "vEthernet (LiveMigration)", "vEthernet (Backup)"
}

# Create and configure Nano S2D Hyper-Converged Cluster
# Validate Cluster

# Test S2D hyper-converged cluster
$Nodes = "NANOSRV-S2D01", "NANOSRV-S2D02", "NANOSRV-S2D03", "NANOSRV-S2D04"
Test-Cluster -Node $Nodes -Include Inventory,Network,"System Configuration",“Storage Spaces Direct” -Verbose

# Create S2D Cluster
New-Cluster -Name NANOS2D-CLU -Node $Nodes -NoStorage -StaticAddress 172.16.20.155/24 -IgnoreNetwork 10.11.0.0/24, 10.13.0.0/24 -Verbose

# Set Cluster Cloud Witness
Set-ClusterQuorum –Cluster NANOS2D-CLU –CloudWitness –AccountName nanohvcloudwitness –AccessKey <AccessKey>

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
$Cluster = "NANOS2D-CLU"
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

# Enable Storage Spaces Direct
$Cluster = "NANOS2D-CLU"
Enable-ClusterStorageSpacesDirect -CimSession $Cluster

# Get supported storage size
Get-StorageTierSupportedSize -FriendlyName Performance -CimSession $Cluster | Select-Object @{l="TierSizeMin(GB)";e={$_.TierSizeMin/1GB}}, @{l="PerformanceTierSizeMax(TB)";e={$_.TierSizeMax/1TB}}, @{l="TierSizeDivisor(GB)";e={$_.TierSizeDivisor/1GB}}
Get-StorageTierSupportedSize -FriendlyName Capacity -CimSession $Cluster    | Select-Object @{l="TierSizeMin(GB)";e={$_.TierSizeMin/1GB}}, @{l="CapacityTierSizeMax(TB)";e={$_.TierSizeMax/1TB}}, @{l="TierSizeDivisor(GB)";e={$_.TierSizeDivisor/1GB}}

# Create four Capacity Volumes 3.5 TB each
$Nodes = "NANOSRV-S2D01", "NANOSRV-S2D02", "NANOSRV-S2D03", "NANOSRV-S2D04"
Foreach ($Node in $Nodes) {
New-Volume -CimSession $Node -StoragePoolFriendlyName S2D* -FriendlyName $Node -FileSystem CSVFS_REFS -StorageTierFriendlyName Capacity -StorageTierSizes 3.5TB
}

# Inspect the volumes
Get-VirtualDisk -CimSession $Cluster | Get-StorageTier | Format-Table FriendlyName, ResiliencySettingName, MediaType, @{l="Size(TB)";e={$_.Size/1TB}} -autosize

# Rename Volume friendly names and mount points accordingly
$CSVFS = Get-ClusterSharedVolume -Cluster $Cluster
Foreach ($Vol in $CSVFS) {
If ($Vol.SharedVolumeInfo.FriendlyVolumeName -match 'Volume\d+$') {
        			If ($Vol.Name -match '\((.*)\)') {
         					$MatchStr1 = $matches[1]
$mountpoint = ($vol.SharedVolumeInfo.FriendlyVolumeName) -replace 'C:','C$'
           					$vol.Name = $MatchStr1
            					$OwnerNode = ($vol.OwnerNode).Name
Rename-Item -Path \\$OwnerNode\$mountpoint -NewName $MatchStr1
       		 		}
   		 		}
}

# Distribute the Volumes across the four nodes
Foreach ($Node in $Nodes) {
Get-ClusterSharedVolume -Cluster $Cluster -Name $Node | Move-ClusterSharedVolume -Node $Node
}

# Create four Clustered VMs on hyper-converged S2D cluster
$vSwitchName = "SETvSwitch"
$Cluster = "NANOS2D-CLU"

1..4 | ForEach-Object {
New-VM -ComputerName NANOSRV-S2D0$_ -Name DEMO-VM0$_ -MemoryStartupBytes 512MB -VHDPath "C:\ClusterStorage\vDisk0$_\DEMO-VM0$_\DEMO-VM0$_.vhdx" -SwitchName $vSwitchName -Path "C:\ClusterStorage\vDisk0$_\" -Generation 2
Set-VM -ComputerName NANOSRV-S2D0$_ -Name DEMO-VM0$_ -ProcessorCount 2

# Rename VM network interface
Get-VMNetworkAdapter -ComputerName NANOSRV-S2D0$_ -VMName DEMO-VM0$_ | Rename-VMNetworkAdapter -NewName "vmNIC01"

# Make the VM highly available
Add-ClusterVirtualMachineRole -Cluster $Cluster -VMName DEMO-VM0$_

# Start Clustered VM
$ClusteredVM = Get-ClusterResource -Cluster $Cluster | Where-Object {$_.ResourceType -eq "Virtual Machine" -and $_.State -eq "Offline"}
Start-ClusterResource -Cluster $Cluster -Name $ClusteredVM
}





