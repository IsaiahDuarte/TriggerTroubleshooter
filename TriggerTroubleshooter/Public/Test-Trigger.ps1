function Test-Trigger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $name,

        [Parameter(Mandatory = $false)]
        [switch] $display
    )

    Write-Verbose "Starting Test-Trigger for trigger name: $name"
    $output = @()

    $dump = Get-ScopedTriggerDump -Name $name
    if ($dump.Count -eq 0) {
        Write-Warning "No data was returned by the query."
        return
    }

    Write-Verbose "Data retrieved from Get-ScopedTriggerDump: $($dump.Count) records found."

    $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $name }
    if (-not $trigger) {
        Write-Warning "Trigger with name '$name' not found."
        return
    }

    Write-Verbose "Trigger found: $trigger"

    $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId

    foreach ($key in $dump.Keys) {
        $record = $dump[$key]

        $rootNode = @{
            ChildNodes = $triggerDetails.FilterNodes
            ExpressionDescriptor = $null
            IsNegation = $false
            LogicalOperator = "And"
        }

        Write-Verbose "Processing record with key: $key"

        $testResult = Test-Node -node $rootNode -data $record

        $data = [pscustomobject]@{
            ThresholdCrossed = $testResult.Result
            WithinSchedule   = Test-Schedule -ScheduleID $triggerDetails.IncidentScheduleId
            ExpressionTree   = $testResult.ExpressionTree
        }

        Write-Verbose "Data populated for key: $key. ThresholdCrossed: $($data.ThresholdCrossed), WithinSchedule: $($data.WithinSchedule)"

        $record.PSObject.Properties | ForEach-Object {
            if ($_.Name -ne "key") {
                $data | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value
            }
        }

        $output += $data
    }

    Write-Verbose "Returning output with $($output.Count) records."

    if($display) {
        Write-Host $($testResult.ExpressionTree.GetExpression(0))
        $testResult.ExpressionTree.WriteExpression(0)
    }

    return $output
}