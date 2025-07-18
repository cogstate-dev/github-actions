param (
    [string]$ProjectPath = ".",
    [string]$ChromePath = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
)

if ($IsWindows) {
    $nugetExe = "nuget.exe"
} else {
    $nugetExe = "mono /usr/local/bin/nuget.exe"
}

if (!(Test-Path $ChromePath)) {
    Write-Error "Chrome not found at $ChromePath"
    exit 1
}

$chromeVersion = (Get-Item $ChromePath).VersionInfo.ProductVersion
$majorVersion = $chromeVersion.Split('.')[0]
Write-Host "Detected Chrome major version: $majorVersion"

# Find all .csproj files that already reference Selenium.WebDriver.ChromeDriver
$csprojFiles = Get-ChildItem -Path . -Recurse -Filter *.csproj | Where-Object {
    $_.FullName -match 'Test' -and
    (Select-String -Path $_.FullName -Pattern 'Selenium.WebDriver.ChromeDriver')
}

if ($csprojFiles.Count -eq 0) {
    Write-Host "No .csproj files with Selenium.WebDriver.ChromeDriver found."
    exit 0
}

foreach ($proj in $csprojFiles) {
    Write-Host "Updating Selenium.WebDriver.ChromeDriver in $($proj.FullName) to version $majorVersion.0.0"
    Invoke-Expression "$nugetExe update $proj.FullName -Id Selenium.WebDriver.ChromeDriver -Version $majorVersion.0.0"
}