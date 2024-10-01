[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [String]
    $Version,
    [parameter(Mandatory=$false)]
    [String]
    $directory = "."
)

$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

Import-Module $PSScriptRoot\..\modules\Version-Control.psm1

New-VersionsJson -version $Version -directory $directory