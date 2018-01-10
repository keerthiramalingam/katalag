param (
    [string]$pp_region = "region not passed",
    [string]$pp_environment = "env  not passed",
    [string]$pp_role = "role not passed",
 )

 Add-Content C:\PerfLogs\output.txt "$(Get-Date) $pp_region XXXXX $pp_environment XXXXX $pp_role"