$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

Import-Module $PSScriptRoot\..\modules\Version-Control.psm1

VerifyAllGitDirectories

