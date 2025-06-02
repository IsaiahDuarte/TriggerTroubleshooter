<#
    .SYNOPSIS
       Uses the TriggerTroubleshooter module to test a trigger against live data.

    .DESCRIPTION
        This script will take a trigger name and tests it against live data and displays
        the results.It Uses the Test-Trigger function to do this.Optionally, it collects
        a Support Trigger Dump.

    .PARAMETER TriggerName
        Specifies the name of the trigger to test.
    
    .PARAMETER OnlyShowObjectsThatWillFireParameter
        Specifies wheather it will show objects that will fire the trigger or not

    .PARAMETER AllRecordsParameter
        Specifies whether it will process all the available records.
    
    .PARAMETER SimulateTriggerParameter
        Specifies wheather it will attempt to simulate the trigger conditions on a computer
        specified by "SimulateOnComputer"
    
    .PARAMETER SimulateOnComputer
        Specifies which computer simulated tests will run on. This computer needs to be connected
        to the monitor and requires the "Trigger Troubleshooter - Simulated Tests" Script Action

    .PARAMETER Records
        Sets the number of records per folder when using invoke-cuquery -Take.
        This parameter is only used if AllRecordsParameter is "False".
    
    .PARAMETER SaveResultsPath
        If provided, it will output the test results to the specified folder path.
    
    .PARAMETER CollectSupportZipParameter
        Indicates whether a Support Dump should be collected after trigger testing.
        This is done by calling Get-SupportTriggerDump.

    .EXAMPLE
        .\TestTriggerScript.ps1 -TriggerName "MyTrigger" -AllRecordsParameter "True"

        Tests the trigger "MyTrigger" and gets the live data using export-cuquery

    .NOTES 
        Version:           1.3.0
        Context:           Computer script running on one of the CU Monitors
        Author:            Isaiah Duarte ->  https://github.com/IsaiahDuarte/TriggerTroubleshooter  
        Requires:          The CU Monitor's ControlUp.PowerShell.User.dll & 9.0.5+
        Creation Date:     1/27/2025    
        Updated:           2/23/2025
    
    .LINK
        https://support.controlup.com/docs/monitor-cluster-powershell-api-cmdlets
        https://support.controlup.com/docs/monitor-cluster-powershell-fields-by-table
        https://support.controlup.com/docs/powershell-cmdlets-for-triggers
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $TriggerName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("False", "True")]
    [string] $OnlyShowObjectsThatWillFireParameter = "False",

    [Parameter(Mandatory = $false)]
    [ValidateSet("False", "True")]
    [string] $AllRecordsParameter = "False",

    [Parameter(Mandatory = $false)]
    [ValidateSet("False", "True")]
    [string] $SimulateTriggerParameter = "False",

    [Parameter(Mandatory = $false)]
    [string] $SimulateOnComputer,

    [Parameter(Mandatory = $false)]
    [ValidateSet("False", "True")]
    [string] $CollectSupportZipParameter = "False",

    [Parameter(Mandatory = $false)]
    [int] $Records = 10,

    [Parameter(Mandatory = $false)]
    [string] $SaveResultsPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("False", "True")]
    [string] $DebugParameter = "False"

)
###ImportModule###
#region SB base start

# Convert the string parameters for AllRecords and CollectSupportZip to Boolean values.
$AllRecords = [System.Convert]::ToBoolean($AllRecordsParameter)
$CollectSupportZip = [System.Convert]::ToBoolean($CollectSupportZipParameter)
$SimulateTrigger = [System.Convert]::ToBoolean($SimulateTriggerParameter)
$Debug = [System.Convert]::ToBoolean($DebugParameter)
$OnlyShowObjectsThatWillFire = [System.Convert]::ToBoolean($OnlyShowObjectsThatWillFireParameter)

if($Debug) {
    $ENV:TRIGGER_TROUBLESHOOTER_LOG_TO_FILE = $true
    $ENV:TRIGGER_TROUBLESHOOTER_LOG_TO_HOST = $true
}

# Null parameters that are N/A
switch ("N/A") {
    $SaveResultsPath { $SaveResultsPath = $null }
    $SimulateOnComputer { $SimulateOnComputer = $null }
}

try {   
    # If we have a path provided and if the path isn't a container, error
    if($null -ne $SaveResultsPath -and !(Test-Path -Path $SaveResultsPath -PathType Container)) {
        throw "$SaveResultsPath is not a valid path"
    } else {
        $SaveResultFullPath = Join-Path -Path $SaveResultsPath -ChildPath "TriggerTroubleshooter-$([DateTime]::Now.ToString("yyyy-dd-M--HH-mm-ss")).txt"
    }

    Write-Output "Importing latest module from monitor"
    
    # Get the latest version of the ControlUp.PowerShell.User.dll using LastWriteTime.
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramW6432")
    $userModulePath = Join-Path -Path $programFiles -ChildPath "\Smart-X\ControlUpMonitor\*\ControlUp.PowerShell.User.dll"
    $latestUserModulePath = (Get-ChildItem $userModulePath -Recurse | Sort-Object LastWriteTime -Descending)[0]
    Import-Module $latestUserModulePath

    # Warn the user if Records is provided along with AllRecords = True,
    # because the Records parameter won’t be used in this scenario.
    if ($AllRecords -eq $true -and $PSBoundParameters.ContainsKey("Records")) {
        Write-Warning "The 'Records' value will be ignored because 'AllRecords' is set to True."
    }

    # Use different testing logic based on whether AllRecords is true.
    Write-Output "`nTesting trigger: $TriggerName"
    if ($AllRecords -eq $true) {
        Write-TTLog "Using Export logic."
        $result = Test-Trigger -Name $TriggerName -AllRecords
    }
    else {
        Write-TTLog "Using Query logic with Records = $Records."
        $result = Test-Trigger -Name $TriggerName -Records $Records
    }

    # If results were returned, display the count and formatted output.
    # If SaveResultsPath was passed, it will process differently.
    if ($null -ne $result -and !$SaveResultsPath) {
        Write-Output "`nTested $($result.count) records against trigger conditions"
        $result.DisplayResult($OnlyShowObjectsThatWillFire)
    }
    elseif ($null -ne $result -and $SaveResultFullPath) {

        Write-Output "`nTested $($result.count) records against trigger conditions"
        Write-Output "Saving results to $SaveResultFullPath"
        $result.BuildResultString(0, "", $OnlyShowObjectsThatWillFire) | Out-File -FilePath $SaveResultFullPath -Force
    }

    # Collecting support dump if specified
    if ($CollectSupportZip) {
        Write-Output "Collecting Support Dump"
        Get-SupportTriggerDump -Name $TriggerName
    }

    # Only specific triggers can be simulated
    if ($SimulateTrigger) {
        Write-TTLog "SimulatedTrigger is set to true"
        Write-TTLog "SimulateOnComputer: $($SimulateOnComputer)"

        $trigger = Get-Trigger -Name $TriggerName

        if (!$trigger) {
            Write-Warning "Unable to find $TriggerName"
            Write-TTLog "Unable to find $TriggerName"
            return
        }

        Write-TTLog "Trigger Type: $($trigger.TriggerType)"

        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.Id

        $splat = @{
            TriggerName = $TriggerName
            ComputerName = $SimulateOnComputer
        }

        $columns = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes

        switch ($trigger.TriggerType) {
            "Windows Event" { 
                $splat.ConditionType = "WindowsEvent"
            }

            "Machine Stress" {
                if($columns -contains "CPU") {
                    $splat.ConditionType = "CPU"
                } elseif ($columns -contains "MemoryInUse") {
                    $splat.ConditionType = "Memory"
                } else {
                    Write-Warning "Trigger Type $($trigger.TriggerType) cannot be simulated. Doesn't contain CPU or MemoryInUse columns"
                    return
                }
            }

            "Logical Disk Stress" {
                if($columns -contains "FreeSpacePercentage") {
                    $splat.ConditionType = "DiskUsage"
                } elseif ($columns -match "DiskKBps|DiskReadKBps|DiskWriteKBps") {
                    $splat.ConditionType = "DiskIO"
                } else {
                    Write-Warning "Trigger Type $($trigger.TriggerType) cannot be simulated. Doesn't contain DiskUsage,DiskKBps,DiskReadKBps,DiskWriteKBps"
                    return
                }
            }

            "Process Ended" {
                $splat.ConditionType = "Process"
            }

            "Process Started" {
                $splat.ConditionType = "Process"
            }

            default {
                Write-Warning "Trigger Type $($trigger.TriggerType) cannot be simulated"
                return
            }
        }
        $simulationResult = Invoke-SimulatedTrigger @splat

        if($simulationResult) {
            $separator = '=' * 60
            Write-Output $separator
            Write-Output "Simulation result: $($simulationResult.TriggerFired)"
            Write-Output $separator
        }
    }
    
}
catch {
    Write-Error $_.Exception.Message
    throw
}
#endregion