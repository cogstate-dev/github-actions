$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

trap
{
    Write-Error "$($_.Exception)`n`nActual Stack Trace:`n$($_.ScriptStackTrace)`n`nError Output Stack Trace:" 
    exit 1
}
$modulepath = Get-ChildItem -recurse -Include Version-Control.psm1
Import-Module $modulePath[0]

VerifyAllGitDirectories