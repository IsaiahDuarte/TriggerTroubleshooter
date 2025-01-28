<#
    .SYNOPSIS
    Tests if a given trigger logic is satisfied based on a dump of data.

    .DESCRIPTION
    The Test-Trigger function evaluates the applicability of a trigger's conditions by processing a dump of the associated data. It examines each record against defined filter nodes and summarizes the results.

    .PARAMETER name
    The trigger name whose conditions, scope, and associated data are to be evaluated.

    .EXAMPLE

    .NOTES
    Integrates multiple functions for comprehensive data analysis, such as Test-Filter for evaluating individual records.
#>
function Test-Trigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $name
    )

    $output = New-Object System.Collections.ArrayList

    $dump = Get-ScopedTriggerDump -Name $name
    if($dump.Count -eq 0) {
        Write-Warning "No data was returned by the query."
        return
    }

    $trigger = Get-CUTriggers | Where-Object {$_.TriggerName -eq $name}
    $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId
    foreach($key in $dump.Keys) {
        $record = $dump[$key]
        $result = Test-Filter -filterNodes $triggerDetails.FilterNodes -data $record

        $data = [pscustomobject]@{
            ThreasholdCrossed = if($result) { $true } else { $false }
            WithinSchedule = Test-Schedule -ScheduleID $triggerDetails.IncidentScheduleId
        }

        $properties = $record | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -ne "key"}
        $properties | Foreach-Object { Add-Member -InputObject $data -MemberType NoteProperty -Name $_.Name -Value $record.$($_.name) }
        $output.Add($data) | Out-Null
    }
    return $output
}
