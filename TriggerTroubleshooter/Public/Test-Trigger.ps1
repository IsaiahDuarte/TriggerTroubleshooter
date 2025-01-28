<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER name

    .EXAMPLE

    .NOTES
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
        $comparisonDataList = [System.Collections.Generic.List[ComparisonData]]::new() # Initialize the comparison data list
        
        $result = Test-Filter -filterNodes $triggerDetails.FilterNodes -data $record -ComparisonDataList ([ref]$comparisonDataList)

        $data = [pscustomobject]@{
            ThresholdCrossed = $result
            WithinSchedule = Test-Schedule -ScheduleID $triggerDetails.IncidentScheduleId
            ComparisonData = $comparisonDataList
        }

        $properties = $record | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -ne "key"}
        foreach ($property in $properties) {
            $data | Add-Member -MemberType NoteProperty -Name $property.Name -Value $record.$($property.Name)
        }

        $output.Add($data) | Out-Null
    }
    return $output
}