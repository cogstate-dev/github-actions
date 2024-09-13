[CmdletBinding()]
param (
    [Parameter()]
    [String] $efVersion,
    [Parameter()]
    [String] $startDirectory, 
    [Parameter()]
    [String] $dotNetVersion 
)


Set-Location $startDirectory
# Create the tools directory
$toolsDir = "tools"
if (-not (Test-Path -Path $toolsDir)) {
    New-Item -Path $toolsDir -ItemType Directory
    Write-Output "Created 'tools' directory."
} else {
    Write-Output "'tools' directory already exists."
}

# Define the paths and files to copy
$binDir = "bin"
$packagesDir = "..\packages\EntityFramework.$($efVersion)"  

# Files to exclude
$excludedFiles = @(
    "$binDir\EntityFramework.dll",
    "$binDir\EntityFramework.SqlServer.dll"
)

$filesToCopy = Get-ChildItem -Path "$binDir\*.dll" | Where-Object {
    -not $excludedFiles -contains $_.FullName
}
foreach ($file in $filesToCopy) {
    Copy-Item -Path $file.FullName -Destination $toolsDir
    Write-Output "Copied $($file.FullName) to $toolsDir"
}

if (Test-Path "NLog.config") {
    Copy-Item -Path "NLog.config" -Destination $toolsDir
    Write-Output "Copied NLog.config to $toolsDir"
} else {
    Write-Output "NLog.config not found."
}

# Copy all files from lib\dotNetVersion\ in EntityFramework package
$netVersionDirectory = "$packagesDir\lib\$dotNetVersion"
if (Test-Path $net45Dir) {
    Copy-Item -Path "$netVersionDirectory\*.*" -Destination $toolsDir -Recurse
    Write-Output "Copied all files from $netVersionDirectory to $toolsDir"
} else {
    Write-Output "$netVersionDirectory directory not found."
}

# Copy migrate.exe from the EntityFramework tools directory
$migrateExePath = "$packagesDir\tools\migrate.exe"
if (Test-Path $migrateExePath) {
    Copy-Item -Path $migrateExePath -Destination $toolsDir
    Write-Output "Copied migrate.exe to $toolsDir"
} else {
    Write-Output "migrate.exe not found."
}