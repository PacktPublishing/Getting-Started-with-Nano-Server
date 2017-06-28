Param
(
    [Parameter(Mandatory=$true)]
    $ConfigNode,                        #specify the target node(s) that you want to configure

	[Parameter(Mandatory=$false)]
    [string]$AdminAccountName,          #specify if you want to manage custom account

	[Parameter(Mandatory=$false)]
    [Boolean]$Enabled=$true,            #solution 'Master Switch'

	[Parameter(Mandatory=$false)]
    [UInt32]$PasswordLength=14,         #chars in password

	[Parameter(Mandatory=$false)]
    [UInt32]$PasswordComplexity=3,      #0=Large, 1=LargeSmall ,2=LargeSmallNum, 3=LargeSmallNumSpec

	[Parameter(Mandatory=$false)]
    [UInt32]$PasswordAge=30,            #max password age in days

	[Parameter(Mandatory=$false)]
    [UInt32]$ManagementInterval=1200,   #seconds (20 mins)

	[Parameter(Mandatory=$false)]
    [bool]$ExpirationProtectionEnabled=$true,   #whether or not to allow password expiration behind the policy. $true=No, $false=Yes

	[Parameter(Mandatory=$false)]
    [UInt32]$LogLevel=0                 #0=Error, 1=ErrorsWarnings, 2=All

)

Configuration LAPS_Nano_Config {
   Param (

      [Parameter()]
      [ValidateSet("Present","Absent")]
      [String]$Ensure = "Present"
   )

   Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

   #List of Nano machine which needs to be configured
    Node $ConfigNode
    {
		$Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft Services\AdmPwd'

		if($AdminAccountName -ne $null)
		{
			Registry AdminAccountName
			{
				Ensure = $Ensure
				Key = $Key
				ValueName = 'AdminAccountName'
				ValueType = 'String'
				ValueData = $AdminAccountName
			}
		}
		else
		{
			Registry AdminAccountName
			{
				Ensure = "Absent"
				Key = $Key
				ValueName = 'AdminAccountName'
				ValueType = 'String'
			}
		}

		Registry Enabled
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'AdmPwdEnabled'
			ValueType = 'DWord'
			ValueData = ($Enabled -as [Int32])
		}

		Registry ExpirationProtectionEnabled
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'PwdExpirationProtectionEnabled'
			ValueType = 'DWord'
			ValueData = ($ExpirationProtectionEnabled -as [Int32])
		}

		Registry PasswordLength
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'PasswordLength'
			ValueType = 'DWord'
			ValueData = $PasswordLength
		}

		Registry PasswordComplexity
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'PasswordComplexity'
			ValueType = 'DWord'
			ValueData = $PasswordComplexity
		}

		Registry PasswordAge
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'PasswordAgeDays'
			ValueType = 'DWord'
			ValueData = $PasswordAge
		}

		Registry ManagementInterval
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'PwdManagementInterval'
			ValueType = 'DWord'
			ValueData = $ManagementInterval
		}

		Registry LogLevel
		{
			Ensure = $Ensure
			Key = $Key
			ValueName = 'LogLevel'
			ValueType = 'DWord'
			ValueData = $LogLevel
		}
	}
}
LAPS_Nano_Config -Ensure Present


