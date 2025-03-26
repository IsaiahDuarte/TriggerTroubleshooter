function Get-TriggerColumns {
    <#
        .SYNOPSIS
            Extracts unique trigger column names from a list of filter nodes.

        .DESCRIPTION
            This function iterates over a list of TriggerFilterNode objects to extract the 'Column'
            property from each node's ExpressionDescriptor.

        .PARAMETER FilterNodes
            A list of ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode objects that
            contain column information.

        .EXAMPLE
            Get-TriggerColumns -FilterNodes $nodes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]]
        $FilterNodes
    )

    try {
        Write-TTLog "Starting Get-TriggerColumns with $($FilterNodes.Count) filter node(s)."
        $columns = [System.Collections.Generic.List[string]]::New()

        foreach ($node in $FilterNodes) {
            Write-TTLog "Processing a node..."

            if ($null -eq $node.ExpressionDescriptor) {
                Write-TTLog "Skipping node with null ExpressionDescriptor."
                continue
            }

            if (-not $node.ExpressionDescriptor.PSObject.Properties['Column']) {
                Write-TTLog "Skipping node without 'Column' property."
                continue
            }

            $columnValue = $node.ExpressionDescriptor.Column
            if ($columnValue -is [string]) {
                Write-TTLog "Adding column: '$columnValue'."
                [void] $columns.Add($columnValue)
            }
            elseif ($columnValue -is [string[]]) {
                Write-TTLog ("Adding array of columns: {0}." -f ($columnValue -join ', '))
                [void] $columns.AddRange($columnValue)
            }
            else {
                Write-TTLog ("Unhandled column property type: {0}. Skipping column." -f $columnValue.GetType().Name)
            }

            # Process child nodes recursively if any exist
            if ($node.ChildNodes -and $node.ChildNodes.Count -gt 0) {
                Write-TTLog "Processing $($node.ChildNodes.Count) child node(s)."
                $childColumns = Get-TriggerColumns -FilterNodes $node.ChildNodes
                if ($childColumns) {
                    Write-TTLog ("Adding child columns: {0}." -f ($childColumns -join ', '))
                    [void] $columns.AddRange($childColumns)
                }
            }
        }

        $uniqueColumns = $columns.ToArray() | Sort-Object -Unique | Where-Object { $_ -ne "" }
        Write-TTLog ("Returning unique columns: {0}." -f ($uniqueColumns -join ', '))
        return $uniqueColumns
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-TriggerColumns: $($_.Exception.Message)"
        throw
    }
}