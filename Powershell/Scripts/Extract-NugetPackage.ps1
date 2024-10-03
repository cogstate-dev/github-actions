[CmdletBinding()]
param (
    [Parameter()]
    [String] $nugetPackageOrDirectory = ".\nuget",
    [Parameter()]
    [String] $outputDirectory = ".\output"
)

# Check if the specified path exists
if (-not (Test-Path $nugetPackageOrDirectory)) {
    Write-Error "The specified path '$nugetPackageOrDirectory' does not exist."
    exit 1
}

# Get the item at the specified path
$item = Get-Item $nugetPackageOrDirectory

if ($item.PSIsContainer) {
    # It's a directory; find the first .nupkg file
    $nupkgFile = Get-ChildItem -Path $nugetPackageOrDirectory -Filter '*.nupkg' | Select-Object -First 1
    if (-not $nupkgFile) {
        Write-Error "No .nupkg file found in the directory '$nugetPackageOrDirectory'."
        exit 1
    }
} elseif ($item -is [System.IO.FileInfo]) {
    # It's a file; check if it's a .nupkg file
    if ($item.Extension -ne '.nupkg') {
        Write-Error "The specified file '$nugetPackageOrDirectory' is not a .nupkg file."
        exit 1
    }
    $nupkgFile = $item
} else {
    Write-Error "The specified path '$nugetPackageOrDirectory' is neither a valid file nor a directory."
    exit 1
}

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

Expand-Archive -Path $nupkgFile.FullName -DestinationPath $outputDirectory -Force

Write-Output "Extraction completed successfully to '$outputDirectory'."
# Write-Output "Contents of the output directory:"
# Get-ChildItem -Path $outputDirectory -Recurse | ForEach-Object { Write-Output $_.FullName }