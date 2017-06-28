Param
(
    [Parameter(Mandatory=$true)]
    $ConfigNode                 #specify the target node(s) that you want to install LAPS Client
 )      

Configuration LAPS_Nano_Install
{
   Param (

      [Parameter()]
      [ValidateSet("Present","Absent")]
      [String]$Ensure = "Present"
   )

   Import-DscResource -ModuleName LAPS.Nano.DSC -ModuleVersion '1.0.0.5'

   #List of Nano machine to install LAPS Client
    Node $ConfigNode
   {

   cLapsNanoInstall Install
   {
    ID = 'LAPS.Nano'
    Ensure = $Ensure
   }

  }

}

LAPS_Nano_Install -Ensure Present
