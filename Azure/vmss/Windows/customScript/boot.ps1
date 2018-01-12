param (
    [string]$pp_region = "region not passed",
    [string]$pp_environment = "env  not passed",
    [string]$pp_role = "role not passed",
    [string]$vmss = ""
 )

New-Item -ItemType directory -Path C:\tst

Add-Content C:\tst\output.txt "$(Get-Date) $pp_region XXXXX $pp_environment XXXXX $pp_role and $vmss"

$onlyScriptURI = $vmss.Split(" ")[0]
$onlyFileName = $onlyScriptURI.Split("\/")[-1]
$localScriptLocation = "C:\tst\" + $onlyFileName

Invoke-WebRequest -Uri $onlyScriptURI -OutFile $localScriptLocation
Invoke-Expression $localScriptLocation $vmss.Split(" ")[1..($vmss.Split(" ").Length)]