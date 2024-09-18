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
    $nunitAppConfigFile,
    [parameter()]
    [string]
    $testFileFilterPattern = "Cogstate.*.Test.dll",
    [parameter()]
    [string]
    $testFileFolderFilter = "*bin",
    [parameter()]
    [string]
    $startInFolder,
    [parameter()]
    [string]
    $dotCoverPath = "D:\BuildAgent\tools\JetBrains.dotCover.CommandLineTools.bundled\dotCover.exe" 
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
$dotCoverPath = "D:\BuildAgent\tools\JetBrains.dotCover.CommandLineTools.bundled\dotCover.exe"
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
            if ($pattern -match '\*') {
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
 
#call nunit3-console
#if (-not $nunitAppConfigFile -or $nunitAppConfigFile -eq ""){
#    Write-Output "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies --config $nunitAppConfigFile"
#    Invoke-Expression "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies --config $nunitAppConfigFile"
#}
#else {
#    Write-Output "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies "
#    Invoke-Expression "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies"
#}

 

 # Get only the full paths of the filtered DLL files
  $testFileList = $filteredDllFiles | Select-Object -ExpandProperty FullName
  #null check the testFileList
if (0 -eq $testFileList.Count) {
    Write-output "Could not find any files matching $testFileFilterPattern  . Check to make sure the base directory to make sure the test File Folder Filter is applicable."
    exit 1
}
   
# Loop through each test DLL and run dotCover for each one separately
foreach ($testFile in $testFileList) {
    & $dotCoverPath cover `
        --targetExecutable="$nunitPath" `
        --output="dotCoverReport_$($testFile | Split-Path -Leaf).dcvr" `
        --reportType="DetailedXML" `
        --returnTargetExitCode `
        -- $testFile --result=TestResult_$($testFile | Split-Path -Leaf).xml --where $nunitExpression
}

 # Merge the coverage reports into one file (optional step)
 
$coverageFiles = @()
foreach ($testFile in $testFileList) {
    # Generate the corresponding coverage report file name based on the test DLL
    $coverageFile = "dotCoverReport_$($testFile | Split-Path -Leaf).dcvr"
    
    # Add the coverage file name to the $coverageFiles list
    $coverageFiles += $coverageFile
}


$coverageFileList = $coverageFiles -join ' '

& $dotCoverPath merge `
    --source $coverageFileList `
    --output="MergedCoverageReport.dcvr" `
    --reportType="DetailedXML"