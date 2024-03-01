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
    [parameter()]
    [string]
    $nugetConfigFullPath = "$pwd\nuget.config"
)
$ErrorActionPreference= 'Stop'

# Clean out all nuget configs
Get-ChildItem -Recurse -Filter "nuget.config" | ForEach-Object {
    if (Test-Path $_.FullName) {
            write-output "removing $_.fullname"
            Remove-Item $_.FullName
        }
    }

# Create a simple nuget.config pointing to the proper proget feed
# Creating config content block
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

# Setting nuget config with content block
$configContent | Set-Content -Path $nugetConfigFullPath

# Update NuGet sources
nuget.exe source update -ConfigFile "$nugetConfigFullPath" -Name proget -Username api -Password $nugetApiKey  
nuget.exe  source update -ConfigFile "$nugetConfigFullPath" -Name proget-lib -Username api -Password $nugetApiKey  
nuget.exe  source update -ConfigFile "$nugetConfigFullPath" -Name proget-deployable -Username api -Password $nugetApiKey  

# Display NuGet sources with detailed verbosity
nuget.exe  source -Verbosity detailed


# Nuget Restore
nuget.exe restore Cogstate.Platform\Cogstate.Platform.sln -force -recursive -ConfigFile .\nuget.config -Verbosity detailed

