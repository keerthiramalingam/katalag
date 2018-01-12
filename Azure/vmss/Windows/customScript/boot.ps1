param (
    [string]$pp_region = "region not passed",
    [string]$pp_environment = "env  not passed",
    [string]$pp_role = "role not passed",
    [string]$vmss = ""
 )

 Add-Content C:\tst\output.txt "$(Get-Date) $pp_region XXXXX $pp_environment XXXXX $pp_role and $vmss"


$parm = "http://google.com/asdasd/etrtrtir/jjglgle.ps1  -parm1 qwqwe -parm2 23232"
$onlyScriptURI = $vmss.Split(" ")[0]
$onlyFileName = $onlyScriptURI.Split("\/")[-1]
$localScriptLocation = "C:\tst\" + $onlyFileName

Invoke-WebRequest -Uri $onlyScriptURI -OutFile $localScriptLocation
Invoke-Expression $localScriptLocation $parm.Split(" ")[1..($parm.Split(" ").Length)]