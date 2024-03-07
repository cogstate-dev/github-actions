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
write-output "setting error action preference to stop"

# Clean out all nuget configs
write-output "Removing"
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
write-output "nuget source update proget"
nuget.exe source update -ConfigFile "$nugetConfigFullPath" -Name proget -Username api -Password $nugetApiKey  
write-output "nuget source update proget-lib"
nuget.exe  source update -ConfigFile "$nugetConfigFullPath" -Name proget-lib -Username api -Password $nugetApiKey
write-output "nuget source update proget-deployable"
nuget.exe  source update -ConfigFile "$nugetConfigFullPath" -Name proget-deployable -Username api -Password $nugetApiKey  

write-output "display nuget sources detailed verbosity"
# Display NuGet sources with detailed verbosity
nuget.exe  source -Verbosity detailed

write-output "nuget restore"
# Nuget Restore
nuget.exe restore Cogstate.Platform\Cogstate.Platform.sln -force -recursive -ConfigFile .\nuget.config -Verbosity detailed