<#
    .SYNOPSIS
       Uses the TriggerTroubleshooter module to test a trigger against live data.

    .DESCRIPTION
        This script will take a trigger name and tests it against live data and displays
        the results.It Uses the Test-Trigger function to do this.Optionally, it collects
        a Support Trigger Dump.

    .PARAMETER TriggerName
        Specifies the name of the trigger to test.

    .PARAMETER UseExportParameter
        Specifies whether export-cuquery will be used to get all the records in scope.
        Please be mindful when using this on triggers that are scoped to all folders.

    .PARAMETER CollectSupportZipParameter
        Indicates whether a Support Dump should be collected after trigger testing.
        This is done by calling Get-SupportTriggerDump which will also dump ALL
        records/fields specified in the trigger. This can be a large zip.

    .PARAMETER RecordsPerFolder
        Sets the number of records per folder when using invoke-cuquery -Take.
        This parameter is only used if UseExport is "False". The default is 1.
        The reason we are processing per folder is to get the correct data in scope of
        the trigger.
    
    .PARAMETER SaveResultsPath
        If provided, it will output the test results to the specified path.

    .EXAMPLE
        .\TestTriggerScript.ps1 -TriggerName "MyTrigger" -UseExportParameter "True"

        Tests the trigger "MyTrigger" and gets the live data using export-cuquery

    .NOTES 
        Version:           1.0.7
        Context:           Computer script running on one of the CU Monitors
        Author:            Isaiah Duarte ->  https://github.com/IsaiahDuarte/TriggerTroubleshooter  
        Requires:          The CU Monitor's ControlUp.PowerShell.User.dll
        Creation Date:     1/27/2025    
        Updated:           2/8/2025
    
    .LINK
        https://support.controlup.com/docs/monitor-cluster-powershell-api-cmdlets
        https://support.controlup.com/docs/monitor-cluster-powershell-fields-by-table
        https://support.controlup.com/docs/powershell-cmdlets-for-triggers
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $TriggerName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("False", "True")]
    [string] $UseExportParameter = "False",

    [Parameter(Mandatory = $false)]
    [ValidateSet("False", "True")]
    [string] $CollectSupportZipParameter = "False",

    [Parameter(Mandatory=$false)]
    [int] $RecordsPerFolder = 1,

    [Parameter(Mandatory = $false)]
    [string] $SaveResultsPath
)

###ImportModule###

#region SB base start

# Set preferences for error handling, verbosity, and debugging.
$ErrorActionPreference = 'Stop' 
$VerbosePreference     = 'SilentlyContinue' 
$DebugPreference       = 'SilentlyContinue' 
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

# Null parameters that are N/A
switch("N/A") {
    $SaveResultsPath { $SaveResultsPath = $null }
}

try {   
    Write-Output "Importing latest module from monitor"
    
    # Get the latest version of the ControlUp.PowerShell.User.dll using LastWriteTime.
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramW6432")
    $userModulePath = Join-Path -Path $programFiles -ChildPath "\Smart-X\ControlUpMonitor\*\ControlUp.PowerShell.User.dll"
    $latestUserModulePath = (Get-ChildItem $userModulePath -Recurse | Sort-Object LastWriteTime -Descending)[0]
    Import-Module $latestUserModulePath

    # Warn the user if RecordsPerFolder is provided along with UseExport = True,
    # because the RecordsPerFolder parameter won’t be used in this scenario.
    if ($UseExport -and $PSBoundParameters.ContainsKey("RecordsPerFolder")) {
        Write-Warning "The 'RecordsPerFolder' value will be ignored because 'UseExport' is set to True."
    }

    # Use different testing logic based on whether UseExport is true.
    Write-Output "`nTesting trigger: $TriggerName"
    if ($UseExport) {
        Write-Verbose "Using Export logic."
        $result = Test-Trigger -Name $TriggerName -UseExport
    } else {
        Write-Verbose "Using Query logic with RecordsPerFolder = $RecordsPerFolder."
        $result = Test-Trigger -Name $TriggerName -RecordsPerFolder $RecordsPerFolder
    }

    # If results were returned, display the count and formatted output.
    # If SaveResultsPath was passed, it will process differently.
    if ($null -ne $result -and !$SaveResultsPath) {
        Write-Output "`nTested $($result.count) records against trigger conditions"
        $result.DisplayResult()
    } elseif ($null -ne $result -and $SaveResultsPath) {
        Write-Output "`nTested $($result.count) records against trigger conditions"
        Write-Output "Saving results to $SaveResultsPath"
        $result.BuildResultString(0, "") | Out-File -FilePath $SaveResultsPath -Force -Append
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
#endregion