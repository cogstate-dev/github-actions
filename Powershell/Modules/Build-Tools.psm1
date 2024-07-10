function Set-NPMRC{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $NPMFeedURL,
        [Parameter()]
        [string]
        $NPMPublishFeedURL,
        [Parameter()]
        [string]
        $NPMFeedUser,
        [Parameter()]
        [string]
        $NPMFeedPwd,
        [Parameter()]
        [string]
        $NPMFeedEmail
    )

    $passwordBytes = [System.Text.Encoding]::ASCII.GetBytes($NPMFeedPwd)
    $base64Password =[Convert]::ToBase64String($passwordBytes)

    $authFeedPath=$NPMFeedUrl.substring(6)
    $authPublishFeedPath=$NPMPublishFeedUrl.substring(6)

$npmRc = @"
always-auth=true
auth-type=legacy
registry=${NPMfeedUrl}
${authFeedPath}:always-auth=true
${authFeedPath}:auth-type=legacy
${authFeedPath}:_password=`"${base64Password}`"
${authFeedPath}:username=${NPMFeedUser}
${authFeedPath}:email=${NPMFeedEmail}
${authPublishFeedPath}:always-auth=true
${authPublishFeedPath}:auth-type=legacy
${authPublishFeedPath}:_password=`"${base64Password}`"
${authPublishFeedPath}:username=${NPMFeedUser}
${authPublishFeedPath}:email=${NPMFeedEmail} 
"@

    Get-ChildItem . -Include .npmrc -Recurse | Remove-Item

    $npmRc | Out-File -FilePath .npmrc -Force

    npm config list
}