function Test-Trigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [switch] $Display,

        [Parameter(Mandatory = $false)]
        [bool] $UseExport = $false
        
    )

    Write-Verbose "Starting Test-Trigger for trigger name: $Name"
    $output = [System.Collections.Generic.List[TriggerFilterResult]]::New()

    Write-Verbose "Getting Trigger"
    $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $Name }
    if (-not $trigger) {
        Write-Warning "Trigger with name '$Name' not found."
        return
    }
    Write-Verbose "Trigger found: $trigger"

    Write-Verbose "Getting trigger configuration"
    $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId

    Write-Verbose "Testing the schedule"
    $scheduleResult = Test-Schedule -ScheduleID $triggerDetails.IncidentScheduleId

    Write-Verbose "Getting trigger dump"
    $dumpSplat = @{
        Name = $Name
        UseExport = $UseExport
        TriggerType = $triggerDetails.TriggerType
        RecordType = $triggerDetails.AdvancedTriggerSettings.TriggerStressRecordType
        Fields = $triggerDetails.FilterNodes.ExpressionDescriptor.Column
    }
    $dump = Get-ScopedTriggerDump @dumpSplat

    if ($dump.Count -eq 0) {
        Write-Warning "No data was returned by the query."
        return
    }
    Write-Verbose "Data retrieved from Get-ScopedTriggerDump: $($dump.Count) records found."


    Write-Verbose "Testing each entry from dump"
    foreach ($key in $dump.Keys) {
        Write-Verbose "Testing $Key"
        $record = $dump[$key]
        
        $rootNode = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::New()
        $rootNode.ChildNodes = $triggerDetails.FilterNodes

        $result = Test-TriggerFilterNode -Node $rootNode -Record $record
        $result.ScheduleResult = $scheduleResult
        [void] $output.Add($result)
        
    }

    Write-Verbose "Returning output with $($output.Count) records."

    if($Display) {
        $output.DisplayResult()
    }

    return $output
}