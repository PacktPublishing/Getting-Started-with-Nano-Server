# Download AV Signatures for Windows Defender
# Feature: Windows Defender
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - June 12, 2017
# Version 2.0
# Note: Chapter 10

#region variables
$destinationPath = "D:\AVSignatures"
#endregion

#region create destination path if does not exist
if (-not (Test-Path -Path $destinationPath)) {
  mkdir -Path $destinationPath
}
#endregion

#region Windows Defender Definitions URL
$x64S1 = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x64"
$x64D1 = $destinationPath + "\mpam-fe.exe"
$x64S2 = "http://go.microsoft.com/fwlink/?LinkId=211054"
$x64D2 = $destinationPath + "\mpam-d.exe"
$x64S3 = "http://go.microsoft.com/fwlink/?LinkID=187316&arch=x64&nri=true"
$x64D3 = $destinationPath + "\nis_full.exe"
#endregion

#region Download Windows Defender Definitions
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($x64S1, $x64D1)
$WebClient.DownloadFile($x64S2, $x64D2)
$WebClient.DownloadFile($x64S3, $x64D3)
#endregion
