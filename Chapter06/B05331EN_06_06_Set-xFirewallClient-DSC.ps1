# Create configuration MOF file and Push DSC configuration
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 20, 2017
# Version 2.0

# Variables
$LocalPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
$LocalCred = New-Object System.Management.Automation.PSCredential ('.\Administrator', $LocalPassword)
$TargetNode = 'NANOVM-OM01','NANOVM-OM02','NANOVM-OM03','NANOVM-OM04','NANOVM-OM05'

Configuration xFirewallClient
{     
      
    # Importing the xNetworking DSC Module
    Import-DscResource -ModuleName xNetworking

    # List of Nano machine which needs to be configured
    Node $TargetNode
    {
        # Enable Built-in ICMPv4-In 
       xFirewall FirewallICMP4In
        {
            Name                  = 'FPS-ICMP4-ERQ-In'
            Ensure                = 'Present'
            Enabled               = 'True'
            Action                = 'Allow'
            Profile               = 'Any'
        }
        
        # Enable Built-in ICMPv6-In 
       xFirewall FirewallICMP6In
        {
            Name                  = 'FPS-ICMP6-ERQ-In'
            Ensure                = 'Present'
            Enabled               = 'True'
            Action                = 'Allow'
            Profile               = 'Any'
        }
        
        # Enable Built-in File and Printer Sharing (SMB-In)
       xFirewall FirewallSMBIn
        {
            Name                  = 'FPS-SMB-In-TCP'
            Ensure                = 'Present'
            Enabled               = 'True'
            Action                = 'Allow'
            Profile               = 'Any'
        }

        # Enable Built-in Hyper-V Replica HTTP Listener (TCP-In)
       xFirewall FirewallHVRHTTPIn
        {
            Name                  = 'VIRT-HVRHTTPL-In-TCP-NoScope'
            Ensure                = 'Present'
            Enabled               = 'True'
            Action                = 'Allow'
            Profile               = ('Domain', 'Private')
        }

         # Enable Built-in Hyper-V Replica HTTPS Listener (TCP-In)
       xFirewall FirewallHVRHTTPSIn
        {
            Name                  = 'VIRT-HVRHTTPSL-In-TCP-NoScope'
            Ensure                = 'Present'
            Enabled               = 'True'
            Action                = 'Allow'
            Profile               = ('Domain', 'Private')
        }
        
    }
}

# Compile the MOF file
xFirewallClient

# Push DSC Configuration
Start-DscConfiguration -Path .\xFirewallClient -Verbose -Wait -ComputerName $TargetNode -credential $LocalCred -Force 

 

