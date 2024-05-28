[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
    [String]
    $nugetSource = "https://proget.cogstate.com/nuget/nuget-dev/",
    #optional cogstate.feed.nuget.release branch = https://proget.cogstate.com/nuget/nuget-approved/ the default value is for feature branches
    [parameter(Mandatory=$true)]
    [String]
    $nugetLibrary = "https://proget.cogstate.com/nuget/cogstate-library-nuget-dev/",
    #optional cogstate.feed.nuget.publish.library.release branch = https://proget.cogstate.com/nuget/cogstate-library-nuget/ the default value is for feature branches
    [parameter(Mandatory=$true)]
    [String]
    $nugetPublish = "https://proget.cogstate.com/nuget/cognigram-releases-dev/",
    #optional cogstate.feed.nuget.publish.deployable.release branch = https://proget.cogstate.com/nuget/cognigram-releases-candidate/ the default value is for feature branches
    [parameter(Mandatory=$true)]
    [string]
    $nugetApiKey,
    [parameter(Mandatory=$false)]
    [string]
    $solutionFile,
    [parameter()]
    [string]
    $nugetConfigFullPath = "$env:GITHUB_WORKSPACE\nuget.config"
)

# Determine OS and set the path to nuget.exe accordingly
if ($IsWindows) {
    $nugetExe = "nuget.exe"
} else {
    $nugetExe = "mono /usr/local/bin/nuget.exe"
}

write-output "setting error action preference to stop"

# Clean out all nuget configs
write-output "Removing all nuget config files"
Get-ChildItem -Recurse -Filter "nuget.config" | ForEach-Object {
    if (Test-Path $_.FullName) {
            write-output "removing $_.fullname"
            Remove-Item $_.FullName
        }
    }

# Create a simple nuget.config pointing to the proper proget feed
# Creating config content block
write-output "setting content config block"
$configContent = 
@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <clear />
        <add key="proget" value="$nugetSource" />
        <add key="proget-deployable" value="$nugetPublish" />
        <add key="proget-lib" value="$nugetLibrary" />
    </packageSources>
    <disabledPackageSources>
        <clear />
    </disabledPackageSources>
</configuration>
"@

write-output "writing block to a config path"
# Setting nuget config with content block
$configContent | Set-Content -Path $nugetConfigFullPath

# Update NuGet sources
write-output "dotnet nuget update source proget"
Invoke-Expression "dotnet nuget update source proget --configfile $nugetConfigFullPath --username api --password $nugetApiKey --store-password-in-clear-text"
write-output "dotnet nuget update source proget-lib"
Invoke-Expression "dotnet nuget update source proget-lib --configfile $nugetConfigFullPath --username api --password $nugetApiKey --store-password-in-clear-text"
write-output "dotnet nuget update source proget-deployable"
Invoke-Expression "dotnet nuget update source proget-deployable --configfile $nugetConfigFullPath --username api --password $nugetApiKey --store-password-in-clear-text"

write-output "display nuget sources detailed verbosity"
# Display NuGet sources with detailed verbosity
Invoke-Expression "$nugetExe source -Verbosity detailed"

if (!([string]::IsNullOrEmpty($solutionFile))) {
    write-output "SolutionFile supplied, running the nuget restore"
    write-output "Contents of the solutionfile variable: $solutionFile"
    # Nuget Restore
    Invoke-Expression "$nugetExe restore $env:GITHUB_WORKSPACE\$solutionFile -force -recursive -ConfigFile $nugetConfigFullPath -Verbosity detailed"
}