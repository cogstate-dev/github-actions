[CmdletBinding()]
param (
    [Parameter()]
    [String] $searchPattern = "",

    [Parameter()]
    [String] $replaceText = "",

    [Parameter()]
    [String] $fileFilter = "*.config",

    [Parameter()]
    [String] $startDirectory = ".",

    [Parameter()]
    [Bool] $failIfNotFound = $false,

    [Parameter()]
    [Bool] $useRegexEscape = $false
)
Write-Output "Search Pattern: $searchPattern"
Write-Output "Replace Text: $replaceText"
# Check if the start directory exists
if (-not (Test-Path -Path $startDirectory)) {
    Write-Error "The start directory '$startDirectory' does not exist."
    exit 1
}

# Check if the file filter is a valid non-empty string
if (-not $fileFilter) {
    Write-Error "The file filter is invalid or empty."
    exit 1
}

# If useRegexEscape is true, escape the search pattern
if ($useRegexEscape) {
    $searchPattern = [regex]::Escape($searchPattern)
} 
else {
    # Validate the regex pattern by attempting to compile it
    try {
        [regex]::new($searchPattern) | Out-Null
    }
    catch {
        Write-Error "The search pattern '$searchPattern' is not a valid regular expression."
        exit 1
    }
}

# Get all files that match $fileFilter recursively starting in the $startDirectory
$files = Get-ChildItem -Path $startDirectory -Recurse -Filter $fileFilter

# Initialize an array to track affected files
$affectedFiles = @()

foreach ($file in $files) {
    # Read the file content
    $content = Get-Content -Path $file.FullName -Raw

    # Check if the content matches the search pattern
    if ($content -match $searchPattern) {
        # Track the file in the list of affected files
        $affectedFiles += $file.FullName

        # Replace the content
        $updatedContent = $content -replace $searchPattern, $replaceText

        # Write the updated content back to the file
        Set-Content -Path $file.FullName -Value $updatedContent
    }
}

# Output the list of affected files
if ($affectedFiles.Count -gt 0) {
    Write-Output "Files that contained '$searchPattern' and were updated:"
    $affectedFiles | ForEach-Object { Write-Output $_ }
} 
else {
    if ($failIfNotFound) {
        Write-Error "No files contained '$searchPattern'."
        exit 1
    }
    else {
        Write-Output "No files contained '$searchPattern'."
    }
}