param (
    [string]$pp_region = "region not passed",
    [string]$pp_environment = "env  not passed",
    [string]$pp_role = "role not passed",
    [string]$vmss = ""
 )

 Add-Content C:\tst\output.txt "$(Get-Date) $pp_region XXXXX $pp_environment XXXXX $pp_role and $vmss"

 Invoke-Expression $vmss

 Add-Content C:\tst\output.txt "done $vmss"