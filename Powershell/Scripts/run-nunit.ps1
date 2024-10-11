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
    $dotCoverPath = "D:\BuildAgent\tools\JetBrains.dotCover.CommandLineTools.bundled\dotCover.exe" ,
    [Parameter(Mandatory = $false, HelpMessage = "Path to nunit3-console.exe")]
    [string]
    $nunitPath
)

if ($nunitPath) {
    # Check if the provided path exists and is a file
    if (Test-Path -Path $nunitPath -PathType Leaf) {
        Write-Output "NUnit path supplied: $nunitPath"
    }
    else {
        Write-Error "The specified nunit3-console.exe was not found at: $nunitPath"
        exit 1
    }
}
else {
    Write-Output "NUnit path not supplied, searching for *NUnit.ConsoleRunner.3.6.1* in subdirectories..."

    try {
        # Search for nunit3-console.exe within directories matching *NUnit.ConsoleRunner.3.6.1*
        $foundItems = Get-ChildItem -Path $(join-path -path $pwd -ChildPath $startInFolder) -Filter nunit3-console.exe -Recurse -ErrorAction Stop |
        Where-Object { $_.DirectoryName -like '*NUnit.ConsoleRunner.3.6.1*' }

        if ($foundItems.Count -eq 0) {
            Write-Error "nunit3-console.exe not found in any subdirectories matching *NUnit.ConsoleRunner.3.6.1*."
            exit 1
        }
        elseif ($foundItems.Count -gt 1) {
            Write-Error "Multiple instances of nunit3-console.exe found:"
            $foundItems | ForEach-Object { Write-Output $_.FullName }
            exit 1
        }
        else {
            $nunitPath = $foundItems[0].FullName
            Write-Output "nunitPath found: $nunitPath"
        }
    }
    catch {
        Write-Error "An error occurred while searching for nunit3-console.exe: $_"
        exit 1
    }
}
 


if (-not (Test-Path -Path $startInFolder)) {
    Write-Error "The start directory $startInFolder does not exist."
    exit 1
}
else {
    Set-Location -Path $startInFolder
    Write-Output "Changed to $startInFolder"
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
                if ($dllFile.FullName -like $pattern) {
                    $filteredDllFiles += $dllFile
                    break  # Exit the inner loop once a match is found
                }
            }
            else {
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

write-output "TestFileList: $testFileList"
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