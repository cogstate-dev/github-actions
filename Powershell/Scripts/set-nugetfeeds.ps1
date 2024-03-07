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
write-output "hello world"