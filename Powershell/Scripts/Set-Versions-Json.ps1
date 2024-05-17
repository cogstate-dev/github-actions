[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [String]
    $Version
)

$WarningPreference = "Continue"
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$DebugPreference = "Continue"

# trap
# {
#     Write-Error "$($_.Exception)`n`nActual Stack Trace:`n$($_.ScriptStackTrace)`n`nError Output Stack Trace:" 
#     exit 1
# }

# $currentDirectory = Get-Location
# Write-Output "Current Directory is: $currentDirectory"

# $parentDirectory = Join-Path -Path $currentDirectory -ChildPath ".."
# Write-Output "Parent directory is: $parentDirectory"

# $modulePath = Get-ChildItem $parentDirectory -Recurse -Filter "Version-Control.psm1" | Select-Object -First 1
# if (-not $modulePath) {
#     Write-Output "Module path not found in current directory, going up a directory..."
#     $parentDirectory = Set-Location (Join-Path -Path $parentDirectory -ChildPath "..")
#     Write-Output "Parent directory is now: $parentDirectory"
#     $modulePath = Get-ChildItem $parentDirectory -Recurse -Filter "Version-Control.psm1" | Select-Object -First 1
# }

# if ($modulePath) {
#     Write-Output "Module path found: $($modulePath.FullName)"
#     Import-Module $modulePath.FullName
# } else {
#     Write-Output "Module path not found. Exiting..."
#     Write-Error "Error: Module path is empty."
#     exit 2
# }

Import-Module $PSScriptRoot\..\modules\Version-Control.psm1

New-VersionsJson -version $Version