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
    [parameter(Mandatory=$true)]
    [string]
    $nugetApiKey
)

#install nunit
Write-Output "installing nunit"
nuget.exe install NUnit -Version 4.0.1 -Source $nugetSource -OutputDirectory $PWD
Write-Output "nunit installed complete"


try{
    [string]$nunitPath = $(Get-ChildItem -Path $PWD -Filter nunit3-console.exe -Recurse | Where-Object { $_.DirectoryName -like '*NUnit.ConsoleRunner.3.6.1*' }).fullname
}
catch{
    write-output "Either Nunit3-console is not there, or there are multiple instances found and it's returning an array"
    exit $LASTEXITCODE
}
#instantiate empty string for the file string
$testFileString = ""

#get all folders with bin
$folderList = $(get-childitem -filter $testFileFolderFilter -recurse -directory).fullname
#iterate Folder list
foreach($folder in $folderList){
    #generate file list based on folders
    $filelist = $(Get-ChildItem -path $folder -recurse -file |Where-Object{$_.name -like $testFileFilterPattern}).fullname
    #nullcheck the file list from each folder
    if($null -ne $filelist){
        #iterate file list for each folder
        foreach($file in $filelist){
            #filter null or empties
            if(!([string]::IsNullOrWhiteSpace($file))){
                #add to string, space seperated, to run in invocation of nunit3-console
                $testFileString += " "
                $testFileString += $file
            }
        }
        $filelist = $null
    }

}

#call nunit3-console
Invoke-Expression "$nunitPath $testFileString --where `"$nunitExpression`" --skipnontestassemblies --config $nunitAppConfigFile"