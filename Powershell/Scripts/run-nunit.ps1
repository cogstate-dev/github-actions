[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $nugetSource = "https://proget.cogstate.com/nuget/nuget-dev/",
    #optional cogstate.feed.nuget.release branch = https://proget.cogstate.com/nuget/nuget-approved/ the default value is for feature branches
    [parameter()]
    [string]
    $nunitExpression = "cat == Unit||cat == Test_Unit",
    [parameter()]
    [string]
    $nugetConfigFullPath = "$pwd\nuget.config",
    [parameter()]
    [string]
    $nunitAppConfigFile = "Cogstate.Platform/Cogstate.Tests.WebApi/App.config",
    [parameter()]
    [string]
    $testFileFilterPattern = "Cogstate.*.Test.dll",
    [parameter()]
    [string]
    $testFileFolderFilter = "*bin",
    [parameter()]
    [string]
    $startInFolder
)
if (-not (Test-Path -Path $startInFolder)) {
    Write-Error "The start directory $startInFolder does not exist."
    exit 1
}
else {
    Set-Location -Path $startInFolder
    Write-Output "Changed to $startInFolder"
}

#install nunit
Write-Output "installing nunit"
nuget.exe install NUnit -Version 4.0.1 -Source $nugetSource -OutputDirectory $PWD
Write-Output "nunit installed complete"


try{
    [string]$nunitPath = $(Get-ChildItem -Path $PWD -Filter nunit3-console.exe -Recurse | Where-Object { $_.DirectoryName -like '*NUnit.ConsoleRunner.3.6.1*' }).fullname
    write-output "nunitPath: $nunitPath"
}
catch{
    write-output "Either Nunit3-console is not there, or there are multiple instances found and it's returning an array"
    if($nunitPath.Length -le 0){
        Write-Output "Determination: the Nunit3-console is not there"
    }
    if($nunitPath.Length -gt 1){
        Write-Output "Determination: there are multiple Nunit3-console instances"
    }
    exit $LASTEXITCODE
}

#write output the current working directory
Write-Output "The current powershell working directory is: $PWD"

#get all folders with file folder filter
$folderList = $(get-childitem -filter $testFileFolderFilter -recurse -directory).fullname

#null check the folderlist
if($null -eq $folderList){
    Write-output "The folderlist was empty for $testFileFolderFilter. Check to make sure the base directory to make sure the test File Folder Filter is applicable."
}

#instantiate empty string for the file string
$testFileString = ""

#iterate Folder list
foreach($folder in $folderList){
    $patterns = $testFileFilterPattern -split ','
    
    # Generate file list based on folders and patterns
    foreach($pattern in $patterns){
        $filelist = Get-ChildItem -path $folder -Include $pattern
        Write-Output "Filelist Post-Filter:"
        Write-Output $filelist
        # Null-check the file list from each folder
        if($null -ne $filelist){
            # Iterate file list for each folder
            foreach($file in $filelist){
                # Filter null or empty entries
                if(!([string]::IsNullOrWhiteSpace($file.FullName))){
                    # Add to string, space separated, to run in invocation of nunit3-console
                    Write-Output "Adding $file.Fullname"
                    $testFileString += " "
                    $testFileString += $file.FullName
                }
            }
            $filelist = $null
        }
        else{
            Write-Output "Filelist for $testFileFilterPattern in $folder is empty."
        }
    }
}


Write-Output "testFileString:"
Write-Output $testFileString

#call nunit3-console
Invoke-Expression "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies --config $nunitAppConfigFile"