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
        $nunitPath = (Resolve-Path $nunitPath).Path
        Write-Output "Resolved NUnit path: $nunitPath"
    }
    else {
        Write-Host "NUnit not found at $nunitPath. Installing NUnit.ConsoleRunner via nuget..."
        $nunitDir = Split-Path $nunitPath -Parent
        if (!(Test-Path $nunitDir)) {
            New-Item -ItemType Directory -Path $nunitDir -Force | Out-Null
        }
        # Install NUnit.ConsoleRunner using nuget.exe and custom source if provided
        $nugetSourceArg = ""
        if ($nugetSource) {
            $nugetSourceArg = "-Source $nugetSource"
        }
        Invoke-Expression "nuget install NUnit.ConsoleRunner -Version 3.18.3 $nugetSourceArg -OutputDirectory $nunitDir"
        $nunitExePath = Get-ChildItem -Path $nunitDir -Recurse -Filter nunit3-console.exe | Select-Object -First 1
        if ($nunitExePath) {
            $nunitPath = $nunitExePath.FullName
            Write-Host "NUnit installed at $nunitPath"
        } else {
            Write-Error "Failed to install nunit3-console.exe"
            exit 1
        }
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

# Get only the full paths of the filtered DLL files
$testFileList = $filteredDllFiles | Select-Object -ExpandProperty FullName

write-output "TestFileList: $testFileList"
if (0 -eq $testFileList.Count) {
    Write-output "Could not find any files matching $testFileFilterPattern."
    exit 1
}

# Use abosolute paths for coverage artifacts otherwise dotcover stores in temp
$coverageFile = Join-Path -Path $pwd "Coverage.dcvr"
$coverageXmlPath = Join-Path -Path $pwd "CoverageReport.xml"
$coverageHtml = Join-Path $pwd "CoverageReport.html"
$testResultFile = Join-Path $pwd "TestResult.xml"

Write-Host "coverage file path: $coverageFile"
Write-Host "coverage xml path: $coverageXmlPath"

# Run all tests and generate coverage reports
& $dotCoverPath cover `
    --targetExecutable="$nunitPath" `
    --output="$coverageFile" `
    --returnTargetExitCode `
    -- @testFileList --result="$testResultFile" --where $nunitExpression


if (-not (Test-Path "$coverageFile")) {
    Write-Error "Failed to generate coverage report at $coverageFile"
    exit 1
}

# Attach the test results to the build
Write-Host "Coverage report generated successfully."

& $dotCoverPath report `
    --Source="$coverageFile" `
    --ReportType="HTML" `
    --Output="$coverageHtml"

& $dotCoverPath report `
    --Source="$coverageFile" `
    --ReportType="XML" `
    --Output="$coverageXmlPath"

[xml]$coverageXml = Get-Content "$coverageXmlPath"
$projectCoverage = $coverageXml.SelectNodes("//Assembly") | ForEach-Object {
    @{
        Name = $_.Name
        CoveragePercent = [decimal]$_.CoveragePercent
    }
}

$coverageTable = "| Project Name | Coverage Percent |
|---------------|-----------------|
" + ($projectCoverage | ForEach-Object { "| $($_.Name) | $($_.CoveragePercent)% |" }) -join "`n"

[xml]$testResults = Get-Content "$testResultFile"

$totalTests   = $testResults.'test-run'.total
$passedTests  = $testResults.'test-run'.passed
$failedTests  = $testResults.'test-run'.failed
$skippedTests = $testResults.'test-run'.skipped

$summary = @"
### ✅ Test & Coverage Summary

#### 📊 Coverage
$coverageTable

#### 🧪 Tests
| Total | Passed | Failed | Skipped |
|-------|--------|--------|---------|
| $totalTests | $passedTests | $failedTests | $skippedTests |

"@

Set-Content -Path $env:GITHUB_STEP_SUMMARY -Value $summary
Write-Host "Summary written to GitHub job summary."
