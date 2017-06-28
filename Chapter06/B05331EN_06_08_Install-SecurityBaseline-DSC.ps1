# Apply GPO Security Policy to Nano Server using PowerShell DSC
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - February 20, 2017
# Requires PowerShell Version 4.0 or above
# Version 2.0

# Variables
$LocalPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
$LocalCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('.\Administrator', $LocalPassword)
$TargetNode = 'NANOVM-OM01','NANOVM-OM02','NANOVM-OM03','NANOVM-OM04','NANOVM-OM05'

Configuration SecurityBaseline
{
    # Importing three DSC Modules  
    Import-DscResource -ModuleName AuditPolicyDsc, SecurityPolicyDSC, GpRegistryPolicy
    
    # List of Nano machine which needs to be configured
    Node $TargetNode
    {
        SecurityTemplate SecurityBaselineInf
        {
            Path = "C:\NanoServer\GPO\GptTmpl.inf"
            IsSingleInstance = "Yes"
        }
        AuditPolicyCsv SecurityBaselineCsv
        {
            CsvPath = "C:\NanoServer\GPO\audit.csv"
            IsSingleInstance = "Yes"
        }
        RegistryPolicy SecurityBaselineGpo
        {
            Path = "C:\NanoServer\GPO\registry.pol"
        }
    }
}

# Compile the MOF file
SecurityBaseline 

# Push DSC Configuration
Start-DscConfiguration -Path .\SecurityBaseline -Verbose -Wait -ComputerName $TargetNode -credential $LocalCred -Force 
