<#
    .SYNOPSIS
        Downloads, imports, and uses the TriggerTroubleshooter module to test a trigger against live data.

    .DESCRIPTION
        This script will take a trigger name and tests it against live data and displays
        the results. It downloads the latest version of the TriggerTroubleshooter module
        from GitHub (unless an offline path is provided), imports the module, and runs
        the Test-Trigger. Optionally, it collects a Support Trigger Dump.

    .PARAMETER TriggerName
        Specifies the name of the trigger to test.

    .PARAMETER UseExport
        Specifies whether export-cuquery will be used to get all the records in scope.
        Please be mindful when using this on triggers that are scoped to all folders.

    .PARAMETER CollectSupportZip
        Indicates whether a Support Dump should be collected after trigger testing.
        This is done by calling Get-SupportTriggerDump which will also dump ALL
        records/fields specified in the trigger. This can be a large zip.

    .PARAMETER RecordsPerFolder
        Sets the number of records per folder when using invoke-cuquery -Take.
        This parameter is only used if UseExport is "False". The default is 1.
        The reason we are processing per folder is to get the correct data in scope of
        the trigger.

    .PARAMETER ModuleOfflinePath
        Specifies a local path to the TriggerTroubleshooter module to be imported offline.
        If provided, the module will be imported from this location rather than downloading
        from GitHub. You can download the module here:
        https://github.com/IsaiahDuarte/TriggerTroubleshooter/releases

    .EXAMPLE
        .\TestTriggerScript.ps1 -TriggerName "MyTrigger" -UseExport "True"

        Downloads or imports the TriggerTroubleshooter module, tests the trigger "MyTrigger" using export-cuquery

    .NOTES 
        Version:           1.0.5
        Context:           Computer script running on one of the CU Monitors
        Author:            Isaiah Duarte ->  https://github.com/IsaiahDuarte/TriggerTroubleshooter  
        Requires:          The CU Monitor's ControlUp.PowerShell.User.dll
        Creation Date:     1/27/2025    
        Updated:           2/8/2025
#>

param (
    [Parameter(Mandatory)]
    [string] $TriggerName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("False", "True")]
    [string] $UseExportParameter = "False",

    [Parameter(Mandatory=$false)]
    [ValidateSet("False", "True")]
    [string] $CollectSupportZipParameter = "False",

    [Parameter(Mandatory=$false)]
    [int] $RecordsPerFolder = 1,

    [Parameter(Mandatory=$false)]
    [string] $ModuleOfflinePath
)

<#
    .SYNOPSIS
        Downloads and extracts the TriggerTroubleshooter module from GitHub.

    .DESCRIPTION
        This helper function downloads a zip file from a provided Git URL, extracts it to a
        temporary folder, and then returns the full path to the module manifest (psd1 file).

    .PARAMETER GitPath
        The URL to download the TriggerTroubleshooter zip file.
    
    .PARAMETER DestinationPath
        The local directory in which to store the downloaded zip and extracted module.
#>
function Get-TriggerTroubleshooter {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $GitPath,

        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string] $DestinationPath
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

# Ensure that TLS 1.2 is used for secure web requests.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 

# Set preferences for error handling, verbosity, and debugging.
$ErrorActionPreference = 'Stop' 
$VerbosePreference     = 'SilentlyContinue' 
$DebugPreference       = 'Continue' 
$ProgressPreference    = 'SilentlyContinue' 
$PSBoundParameters.GetEnumerator() | Foreach-Object { 
    Switch ($_.Key) { 
        'verbose'     { $VerbosePreference = $_.Value } 
        'debug'       { $DebugPreference = $_.Value } 
        'erroraction' { $ErrorActionPreference = $_.Value } 
    } 
}

# Convert the string parameters for UseExport and CollectSupportZip to Boolean values.
$UseExport = [System.Convert]::ToBoolean($UseExportParameter)
$CollectSupportZip = [System.Convert]::ToBoolean($CollectSupportZipParameter)

# Define the GitHub API URL to fetch the latest release details.
$githubURL = 'https://api.github.com/repos/IsaiahDuarte/TriggerTroubleshooter/releases/latest'

try {   
    Write-Output "Importing latest module from monitor"

    # This is required to import and use the TriggerTroubleshooter module.
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramW6432")

    # Location where TriggerTroubleshooter will be downloaded if offline path
    # is not specified
    $tempDir = [system.IO.Path]::GetTempPath()
    
    # Get the latest version of the ControlUp.PowerShell.User.dll using LastWriteTime.
    $userModulePath = Join-Path -Path $programFiles -ChildPath "\Smart-X\ControlUpMonitor\*\ControlUp.PowerShell.User.dll"
    $latestUserModulePath = (Get-ChildItem $userModulePath -Recurse | Sort-Object LastWriteTime -Descending)[0]
    Import-Module $latestUserModulePath

    # Warn the user if RecordsPerFolder is provided along with UseExport = True,
    # because the RecordsPerFolder parameter won’t be used in this scenario.
    if ($UseExport -and $PSBoundParameters.ContainsKey("RecordsPerFolder")) {
        Write-Warning "The 'RecordsPerFolder' value will be ignored because 'UseExport' is set to True."
    }

     # If a local offline path was specified for the module, import it from that path.
    if ($ModuleOfflinePath -and $ModuleOfflinePath -ne "NA") {
        Write-Output "Importing TriggerTroubleshooter from offline path: $ModuleOfflinePath"
        Import-Module $ModuleOfflinePath
    } else {
        Write-Debug "Downloading TriggerTroubleshooter from Github"
        $LatestVersion = Invoke-WebRequest -Uri $githubURL -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json
        $downloadUrl = ($LatestVersion.Assets | Where-Object { $_.Name -eq 'TriggerTroubleshooter.zip' }).browser_download_url
        $path = Get-TriggerTroubleshooter -GitPath $downloadUrl -DestinationPath $tempDir
        
        Write-Output "Importing TriggerTroubleshooter module"
        Import-Module $path
    }

    # Use different testing logic based on whether UseExport is true.
    Write-Output "`nTesting trigger: $TriggerName"
    if ($UseExport) {
        Write-Debug "Using Export logic."
        $result = Test-Trigger -Name $TriggerName -UseExport $true
    } else {
        Write-Debug "Using Query logic with RecordsPerFolder = $RecordsPerFolder."
        $result = Test-Trigger -Name $TriggerName -RecordsPerFolder $RecordsPerFolder
    }

    # If results were returned, display the count and formatted output.
    if ($null -ne $result) {
        Write-Output "`nTested $($result.count) records against trigger conditions"
        $result.DisplayResult()
    }

    # Collecting support dump if specified
    if ($CollectSupportZip) {
        Write-Output "Collecting Support Dump"
        Get-SupportTriggerDump -Name $TriggerName
    }
    
} catch {
    Write-Error $_.Exception.Message
    throw
} 