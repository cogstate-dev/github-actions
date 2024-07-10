[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $NPMFeedURL,
    [Parameter(Mandatory=$true)]
    [string]
    $NPMPublishFeedURL,
    [Parameter(Mandatory=$true)]
    [string]
    $NPMFeedUser,
    [Parameter(Mandatory=$true)]
    [string]
    $NPMFeedPwd,
    [Parameter(Mandatory=$true)]
    [string]
    $NPMFeedEmail,
    [Parameter(Mandatory=$false)]
    [string]
    $Path
)

Begin{
    $WarningPreference = "Continue"
    $ErrorActionPreference = "Stop"
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"

    Import-Module $PSScriptRoot\..\modules\Build-Tools.psm1
    
    if($Path){
        Push-Location $Path
    }
}
Process{
    Set-NPMRC -NPMFeedURL $NPMFeedURL -NPMPublishFeedURL $NPMPublishFeedURL -NPMFeedUser $NPMFeedUser -NPMFeedPwd $NPMFeedPwd -NPMFeedEmail $NPMFeedEmail
}
End{
    Pop-Location
}
