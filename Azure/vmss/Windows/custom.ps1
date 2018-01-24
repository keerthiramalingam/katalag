param (
    [string]$parm = ""
 )

Add-Content C:\tst\load.ps1 "@echo off"
Add-Content C:\tst\load.ps1 ":loop"
Add-Content C:\tst\load.ps1 "goto loop"

Add-Content C:\tst\load.ps1 $parm