function Set-AssemblyVersion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AssemblyFile,
        [Parameter(Mandatory = $true)]
        [string]$AssemblyVersionInput
    )

    $file = $AssemblyFile
    $fullVersion = $AssemblyVersionInput
    $numericSegments = ($fullVersion -replace '[^0-9\.]', '').Split('.')
    $assemblyVersion = ($numericSegments[0..([Math]::Min($numericSegments.Count,4)-1)] -join '.')
    Write-Host "Setting AssemblyVersion to $assemblyVersion and AssemblyInformationalVersion to $fullVersion in $file"
    (Get-Content $file) -replace 'AssemblyVersion\(".*"\)', "AssemblyVersion(`"$assemblyVersion`")" |
        ForEach-Object {
            $_ -replace 'AssemblyInformationalVersion\(".*"\)', "AssemblyInformationalVersion(`"$fullVersion`")"
        } | Set-Content $file
    # If AssemblyInformationalVersion is not present, add it
    if (-not (Select-String -Path $file -Pattern 'AssemblyInformationalVersion')) {
        Add-Content $file "[assembly: AssemblyInformationalVersion(`"$fullVersion`")]"
    }
}