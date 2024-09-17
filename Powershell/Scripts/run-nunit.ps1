[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $nugetSource = "https://proget.cogstate.com/nuget/nuget-dev/",
    #optional cogstate.feed.nuget.release branch = https://proget.cogstate.com/nuget/nuget-approved/ the default value is for feature branches
    [parameter()]
    [string]
    $nunitExpression = "cat == Unit||cat == Test_Unit",
    [parameter()]
    [string]
    $nugetConfigFullPath = "$pwd\nuget.config",
    [parameter()]
    [string]
    $nunitAppConfigFile = "Cogstate.Platform/Cogstate.Tests.WebApi/App.config",
    [parameter()]
    [string]
    $testFileFilterPattern = "Cogstate.*.Test.dll",
    [parameter()]
    [string]
    $testFileFolderFilter = "*bin",
    [parameter()]
    [string]
    $startInFolder
)
if (-not (Test-Path -Path $startInFolder)) {
    Write-Error "The start directory $startInFolder does not exist."
    exit 1
}
else {
    Set-Location -Path $startInFolder
    Write-Output "Changed to $startInFolder"
}

#install nunit
Write-Output "installing nunit"
nuget.exe install NUnit -Version 4.0.1 -Source $nugetSource -OutputDirectory $PWD
Write-Output "nunit installed complete"


try {
    [string]$nunitPath = $(Get-ChildItem -Path $PWD -Filter nunit3-console.exe -Recurse | Where-Object { $_.DirectoryName -like '*NUnit.ConsoleRunner.3.6.1*' }).fullname
    write-output "nunitPath: $nunitPath"
}
catch {
    write-output "Either Nunit3-console is not there, or there are multiple instances found and it's returning an array"
    if ($nunitPath.Length -le 0) {
        Write-Output "Determination: the Nunit3-console is not there"
    }
    if ($nunitPath.Length -gt 1) {
        Write-Output "Determination: there are multiple Nunit3-console instances"
    }
    exit $LASTEXITCODE
}

# Define the search path
$searchPath = $pwd

#write output the current working directory
Write-Output "The current powershell working directory is: $searchPath"

$dllPatterns = $testFileFilterPattern -split ',' | ForEach-Object { $_.Trim() }

# Get all DLL files in the directory and subdirectories
$allDllFiles = Get-ChildItem -Path $searchPath -Filter "*.dll" -Recurse

# Define an empty list to store the filtered DLL files
$filteredDllFiles = @()


foreach ($dllFile in $allDllFiles) {
    # Check if the DLL file is in the Debug or Release directories
    if ($dllFile.FullName -match "\\bin\\(Debug|Release)\\") {
        # Iterate over each pattern in $dllPatterns
        foreach ($pattern in $dllPatterns) {
            if ($pattern -like "*.*.*") {
                # If the pattern contains wildcards, use -like to match
                if ($dllFile.Name -like $pattern) {
                    $filteredDllFiles += $dllFile
                    break  # Exit the inner loop once a match is found
                }
            } else {
                # For exact matches, use -eq
                if ($dllFile.Name -eq $pattern) {
                    $filteredDllFiles += $dllFile
                    break  # Exit the inner loop once a match is found
                }
            }
        }
    }
}

# Get only the full paths of the filtered DLL files
$foundDlls = $filteredDllFiles | Select-Object -ExpandProperty FullName

#null check the foundDlls
if ($null -eq $foundDlls) {
    Write-output "Could not find any files matching $testFileFilterPattern  . Check to make sure the base directory to make sure the test File Folder Filter is applicable."
    exit 1
}

# create a string of the dlls, each separated by a space
$testFileString = $foundDlls -join " "


Write-Output "testFileString:"
Write-Output $testFileString

#call nunit3-console
Invoke-Expression "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies --config $nunitAppConfigFile"