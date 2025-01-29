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

    [System.Collections.Generic.List[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]] $triggerFilter = $triggerDetails.FilterNodes

    foreach ($key in $dump.Keys) {
        $record = $dump[$key]
        
        $syntheticRootNode = [PSCustomObject]@{
            ExpressionDescriptor = $null 
            IsNegation           = $false
            LogicalOperator      = 'And' 
            ChildNodes           = $TriggerFilter
        }

        $output += Test-TriggerFilterNode -Node $syntheticRootNode -Record $record
        
    }

    Write-Verbose "Returning output with $($output.Count) records."

    if($display) {
        Write-TriggerFilterResult -Nodes $output
    }

    return $output
}