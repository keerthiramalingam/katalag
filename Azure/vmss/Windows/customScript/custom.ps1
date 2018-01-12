param (
    [string]$parm1 = "",
    [string]$parm2 = ""
 )

Add-Content C:\tst\load.ps1 "@echo off"
Add-Content C:\tst\load.ps1 ":loop"
Add-Content C:\tst\load.ps1 "goto loop"

Add-Content C:\tst\load.ps1 $parm1 $parm2