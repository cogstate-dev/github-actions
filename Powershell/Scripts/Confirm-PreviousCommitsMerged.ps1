$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

trap
{
    Write-Error "$($_.Exception)`n`nActual Stack Trace:`n$($_.ScriptStackTrace)`n`nError Output Stack Trace:" 
    exit 1
}

$modulePath = Join-Path $PSScriptRoot "\modules\Version-Control.psm1"
Import-Module $modulePath

VerifyAllGitDirectories