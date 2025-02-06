<#
.SYNOPSIS
    Downloads, imports, and uses the TriggerTroubleshooter module to test a specified trigger.

.DESCRIPTION
    This script will take a trigger name and tests it against live data and displays the results. It downloads the latest version of the
    TriggerTroubleshooter module from GitHub (unless an offline path is provided), imports the module,
    and runs the Test-Trigger. Optionally, it collects a Support Trigger Dump.

.PARAMETER TriggerName
    Specifies the name of the trigger to test.

.PARAMETER UseExport
    Specifies whether export-cuquery will be used to get all the records in scope.

.PARAMETER CollectSupportZip
    Indicates whether a Support Dump should be collected after trigger testing.

.PARAMETER RecordsPerFolder
    Sets the number of records per folder when using invoke-cuquery -Take.
    This parameter is only used if UseExport is "False". The default is 5.

.PARAMETER ModuleOfflinePath
    Specifies a local path to the TriggerTroubleshooter module to be imported offline.
    If provided, the module will be imported from this location rather than downloading from GitHub.

.PARAMETER EnableVerbose
    When specified, sets the Verbose output mode to display additional information during script execution.

.EXAMPLE
    .\TestTriggerScript.ps1 -TriggerName "MyTrigger" -UseExport "True" -EnableVerbose

    Downloads or imports the TriggerTroubleshooter module, tests the trigger "MyTrigger" using export logic,
    displays verbose output.
#>

param (
    [Parameter(Mandatory)]
    [string]$TriggerName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("False", "True")]
    [string]$UseExport = "False",

    [Parameter(Mandatory=$false)]
    [ValidateSet("False", "True")]
    [string]$CollectSupportZip = "False",

    [Parameter(Mandatory=$false)]
    [int]$RecordsPerFolder = 5,

    [Parameter(Mandatory=$false)]
    [string]$ModuleOfflinePath,

    [Parameter(Mandatory=$false)]
    [ValidateSet("False", "True")]
    [string]$EnableVerbose
)

if ($EnableVerbose -eq "True") {
    $VerbosePreference = "Continue"
}

function Get-GitPath {
    param(
        [string]$URL = 'https://api.github.com/repos/IsaiahDuarte/TriggerTroubleshooter/releases/latest'
    )
    $LatestVersion = Invoke-WebRequest -Uri $URL -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json
    return ($LatestVersion.Assets | Where-Object { $_.Name -eq 'TriggerTroubleshooter.zip' }).browser_download_url
}

function Get-TriggerTroubleshooter {
    param(
        [string]$GitPath,
        [string]$DestinationPath
    )
    try {
        $zipPath = Join-Path $DestinationPath "TriggerTroubleshooter.zip"
        $folderPath = Join-Path -Path $DestinationPath -ChildPath "TriggerTroubleshooter"
        Invoke-WebRequest -Uri $GitPath -OutFile $zipPath -UseBasicParsing
        Unblock-File $zipPath

        Expand-Archive -Path $zipPath -DestinationPath $folderPath -Force
        Remove-Item -Path $zipPath -Force

        $modulePath = Get-ChildItem -Path $folderPath -Filter "TriggerTroubleshooter.psd1" -Recurse | Select-Object -First 1 -ExpandProperty FullName
        return $modulePath
    }
    catch {
        Write-Error "Failed to download or extract TriggerTroubleshooter: $_"
        exit 1
    }
}

try {
    Write-Host "Importing latest module from monitor"
    $pathToUserModule = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.PowerShell.User.dll" -Recurse | Sort-Object LastWriteTime -Descending)[0]
    Import-Module $pathToUserModule

    if ($UseExport -eq "True" -and $PSBoundParameters.ContainsKey("RecordsPerFolder")) {
        Write-Verbose "The 'RecordsPerFolder' value will be ignored because 'UseExport' is set to True."
    }
    if ($ModuleOfflinePath -and $ModuleOfflinePath -ne "NA") {
        Write-Host "Importing TriggerTroubleshooter from offline path: $ModuleOfflinePath"
        Import-Module $ModuleOfflinePath
    }
    else {
        Write-Verbose "Downloading TriggerTroubleshooter from Github"
        $downloadUrl = Get-GitPath
        $path = Get-TriggerTroubleshooter -GitPath $downloadUrl -DestinationPath $ENV:TEMP
        Write-Host "Importing TriggerTroubleshooter module"
        Import-Module $path
    }
    Write-Host "`nTesting trigger: $TriggerName"
    if ($UseExport -eq "True") {
        Write-Verbose "Using Export logic."
        $result = Test-Trigger -Name $TriggerName -UseExport $true
    }
    else {
        Write-Verbose "Using Query logic with RecordsPerFolder = $RecordsPerFolder."
        $result = Test-Trigger -Name $TriggerName -RecordsPerFolder $RecordsPerFolder
    }
    if ($null -ne $result) {
        Write-Host "`nTested $($result.count) records against trigger conditions"
        $result.DisplayResult()
    }
    if ($CollectSupportZip -eq "True") {
        Write-Host "Collecting Support Dump"
        Get-SupportTriggerDump -Name $TriggerName
    }
} catch {
    Write-Error $_.Exception.Message
    throw
} 