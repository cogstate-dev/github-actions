function SafeCallBase {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $command
    )

    $local:output = $null
    $local:success = $false

    try {
        $output = Invoke-Expression -Command "& $command 2>&1" 
        $success = $true
    }
    catch {
    }

    return @{
        success = $success;
        output = $output;
    }
}

function SafeCall {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $command,

        [Parameter()]
        [Boolean]
        $returnOutput = $true
    )

    $local:return = SafeCallBase $command

    if ($return.success)
    {
        if ($returnOutput)
        {
            return $return.output
        }
    }
    else 
    {
        throw "Error calling command: ${command}:`n${return.output}`n`n"
    }
}

function MatchAll
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String[]]
        $values,

        [Parameter()]
        [String]
        $regex
    )

    $local:return = @()
    $values | ForEach-Object { 
        if ($_ -cmatch $regex) 
        {
            $return += $Matches
        }
    }

    return $return
}

function GetOrderedReleaseBranches
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]
        $gitDirectory
    )
    $local:branches = SafeCall "git -C `"${gitDirectory}`" branch --remote --format `"%(refname)`""
    $local:releaseBranches = @(MatchAll $branches "^(?<refName>refs/remotes/(?<fullBranchName>(?<remoteName>[^/]+?)/(?<branchName>release/(?<fullReleaseName>(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?<tag>.*)))))$")
    $releaseBranches = $releaseBranches | Sort-Object -Property {[int]$_.major}, {[int]$_.minor}, {[int]$_.patch}, {$_.tag}
    return $releaseBranches
}

function CheckMerged {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $gitDirectory,

        [Parameter()]
        [String]
        $oldBranch,

        [Parameter()]
        [String]
        $newBranch
    )

	$local:checkMergedCommand = "git -C `"${gitDirectory}`" --no-pager log --decorate=short --pretty=oneline -n1 ${newBranch}..${oldBranch}" 
    $local:result = SafeCallBase $checkMergedCommand
	# Output from git log
	#write-host "debug:" $result.output
    return ($result.output.Length -eq 0);
}

function GetCurrentBranchInformation
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [String]
        $gitDirectory
    )

    $local:currentBranch = SafeCall ("git -C `"${gitDirectory}`" status -b --porcelain")
    $currentBranch = @(MatchAll $currentBranch '^## (?:(?:HEAD \(no branch\))|(?:(?<branchName>.*?)(?:\.\.\.(?<remoteBranch>(?<remote>.*?)/(?<remoteBranchName>.*)))?))$')
    
    if ($currentBranch.Count -ne 1)
    {
        throw "Either 0 or more than 1 branch information was returned.";
    }

    $currentBranch = $currentBranch[0]
    $local:branchName = $currentBranch["branchName"]
    $local:releaseNum = $null
    if ($branchName -cmatch "^(?:release|feature)/(?<releaseNum>\d+\.\d+\.\d+.*?)(?:/.*)?$")
    {
        $releaseNum = $Matches["releaseNum"];
    }
    $currentBranch = @{
        branchName = $branchName;
        remote = $currentBranch.remote;
        releaseNum = $releaseNum;
        remoteBranchName = $currentBranch.remoteBranchName;
        remoteBranch = $currentBranch.remoteBranch
    }
    return $currentBranch
}

function CompareVersions 
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        $firstVersion,

        [Parameter()]
        $secondVersion
    )

    if (([int]$firstVersion.major) -gt ([int]$secondVersion.major)) 
    {
        return 1;
    }
    elseif (([int]$firstVersion.major) -lt ([int]$secondVersion.major)) 
    {
        return -1;
    }
    else #($firstVersion.major -eq $secondVersion.major) 
    {
        if (([int]$firstVersion.minor) -gt ([int]$secondVersion.minor))
        {
            return 1;
        }
        elseif (([int]$firstVersion.minor) -lt ([int]$secondVersion.minor))
        {
            return -1;
        }
        else #($firstVersion.minor -eq $secondVersion.minor)
        {
            if (([int]$firstVersion.patch) -gt ([int]$secondVersion.patch))
            {
                return 1;
            }
            elseif (([int]$firstVersion.patch) -lt ([int]$secondVersion.patch))
            {
                return -1;
            }
            else # ($firstVersion -eq $secondVersion.patch)
            {
                if (([string]$firstVersion.tag) -gt ([string]$secondVersion.tag))
                {
                    return 1;
                }
                elseif (([string]$firstVersion.tag) -lt ([string]$secondVersion.tag))
                {
                    return -1;
                }
                else #($firstVersion.tag -eq $secondVersion.tag)
                {
                    # Same Version!
                    return 0;
                }
            }
        }
    }
}

function VerifyCurrentBranch
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $gitDirectory
    )

    $local:masterRelease = @{
        refName = "refs/remotes/origin/master";
        branchName = "master"
    }

    Write-Host "Verifying git directory `"${gitDirectory}`""

    # Update 
    #SafeCall 'git fetch --all' $false
    
    
    # Get the current branch information version this branch is
    $local:currentBranch = GetCurrentBranchInformation $gitDirectory
    $local:currentBranchName = $currentBranch.branchName
    $local:currentReleaseNum = $currentBranch.releaseNum
    if (-not $currentBranchName)
    {
        Write-Host "::warning Can't get information about current branch, no branch name detected, skipping other checks.";
        return $true
    }
    if (-not $currentReleaseNum)
    {
        Write-Host "::warning Can't get release information from current branch.  Skipping other checks.'";
        return $true
    }
    if (-not ($currentReleaseNum -cmatch '^(?<test>(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?<tag>.*))$'))
    {
        Write-Host "::warning Can't get release information from current branch, release number not in proper format.  Skipping other checks.'";
        return $true
    }
    $local:currentReleaseInfo = @{
        releaseNum = $currentReleaseNum;
        major = [int]$Matches["major"];
        minor = [int]$Matches["minor"];
        patch = [int]$Matches["patch"];
        tag = $Matches["tag"];
    }
    Write-Host "Current Branch is '${currentBranchName}' and is linked to release '${currentReleaseNum}'";

    # Get Release Branches in proper order
    $local:releaseBranches = GetOrderedReleaseBranches $gitDirectory

    # Get all branches that are merged into master
    $local:mergedBranches = @{}
    SafeCall ("git -C `"${gitDirectory}`" branch --remote --format `"%(refname)`" --merged ${masterRelease.refName}") | ForEach-Object { $mergedBranches[$_] = $true }

    # For Master and each release branch, determine if it is before the current release and if so, verify that it has been merged in to this branch
    $local:releaseMissingCodeFrom = @()

    # Find latest release version number merged into master 
    $local:latestMergedRelease = $currentReleaseInfo
    $releaseBranches | ForEach-Object {
        if ($mergedBranches[$_.refName])
        {
            $latestMergedRelease = $_
        }
    }
    # if the version we are using is equal or later than the latest release on master, check against master.
    if ((CompareVersions $currentReleaseInfo $latestMergedRelease) -ge 0)
    {
        # Check that master has been fully merged into this branch.
        Write-Host "Checking branch '${currentBranchName}' against master branch.";
        if (-not (CheckMerged $gitDirectory $masterRelease.refName 'HEAD'))
        {
            $releaseMissingCodeFrom += $masterRelease.branchName
        }
    }

    # Check each release branch
    $releaseBranches | ForEach-Object {
        $local:release = $_
        $local:releaseRefName = $release.refName
        $local:releaseBranch = $release.branchName

        $local:releaseComparision = CompareVersions $release $currentReleaseInfo
        if ($releaseComparision -eq 1)
        {
            # Newer release, exit the ForEach-Object script block (not the function!)
            return;
        }

        # Release needs to be checked...
	    Write-Host "Checking branch '${currentBranchName}' against branch '${releaseBranch}'";

        if (-not (CheckMerged $gitDirectory $releaseRefName $currentBranchName))
        {
            $releaseMissingCodeFrom += $release.branchName
        }
    }

    if ($releaseMissingCodeFrom.Count -ne 0)
    {
        $releaseMissingCodeFrom | ForEach-Object {
            Write-Host "Branch '${currentBranchName}' in '${gitDirectory}' is missing commits from: '$_'" 
        }
        Write-Host "Some commits haven't been merged for branch '${currentBranchName}' in '${gitDirectory}"
        return $false
    }
    else 
    {
        Write-Host "Branch '${currentBranchName}' in '${gitDirectory}' was verified successfully"
        return $true
    }
}

function VerifyAllGitDirectories
{
    $local:allDirectoriesPass = $true
    $local:gitDirs = Get-ChildItem -Path . -Attributes Directory+Hidden,Directory+!Hidden -Depth 1 | Where-Object -Property Name -eq ".git" | Select-Object -ExpandProperty Parent | Select-Object -ExpandProperty FullName | Resolve-Path -Relative
    $gitDirs | ForEach-Object {
        Write-Host "::group::Verifying git commits for directory '$_'"
        $local:success = (VerifyCurrentBranch $_)
        $allDirectoriesPass = $allDirectoriesPass -and $success 
        Write-Host "::endgroup::"
    }
    
    if ($allDirectoriesPass) {
		$summary =  "All git directories were verified successfully"
        Write-Host $summary
		exit 0
    }
    else
	{
        Write-Host "At least one git directory was not verified successfully."
		Write-Host $summary
		exit 1
	}
}

function Invoke-ConfigTransformation {
    param(
        [string]$OriginalConfig,
        [string]$TransformConfig,
        [string]$OutputConfig,
        [string]$MsBuildPath
    )
    # Load the assembly
    $transformXmlPath = (Get-ChildItem "$msbuildpath\..\..\..\MSBuild\Microsoft\Visualstudio\v15.0\Web\" -Filter "Microsoft.Web.XmlTransform.dll" -File -Recurse).FullName
    try {
        [System.Reflection.Assembly]::LoadFrom($transformXmlPath)
    }
    catch {
        Write-Host "Failed to load assembly: $_"
        exit 1
    }

    # Create an instance of XmlTransformableDocument
    $doc = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
    $doc.PreserveWhitespace = $true

    # Load the original config file
    try {
        $doc.Load($OriginalConfig)
    }
    catch {
        Write-Host "Failed to load original config file: $_"
        exit 1
    }

    # Load the transform file
    $transformation = New-Object Microsoft.Web.XmlTransform.XmlTransformation($TransformConfig)

    # Apply the transformation
    try {
        $success = $transformation.Apply($doc)
    }
    catch {
        Write-Host "Failed to apply transformation: $_"
        exit 1
    }

    # Save the transformed config
    if ($success) {
        try {
            $doc.Save($OutputConfig)
            Write-Host "Transformation applied successfully. Output saved to: $OutputConfig"
        }
        catch {
            Write-Host "Failed to save output config file: $_"
            exit 1
        }
    }
    else {
        Write-Host "Transformation failed."
        exit 1
    }
}