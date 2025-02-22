function Get-TriggerColumns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]]
        $FilterNodes
    )

    Write-Verbose "Starting Get-TriggerColumns with $($FilterNodes.Count) filter node(s)."

    $columns = [System.Collections.Generic.List[string]]::New()

    foreach ($node in $FilterNodes) {
        Write-Verbose "Processing a node..."

        if ($null -eq $node.ExpressionDescriptor) {
            Write-Verbose "Skipping node because ExpressionDescriptor is null."
            continue
        }

        # Check if the ExpressionDescriptor has a Column
        if (-not $node.ExpressionDescriptor.PSObject.Properties['Column']) {
            Write-Verbose "Skipping node because ExpressionDescriptor doesn't have a 'Column' property."
            continue
        }

        # Process the Column property whether it is a single string or an array of strings
        $columnValue = $node.ExpressionDescriptor.Column
        if ($columnValue -is [string]) {
            Write-Verbose "Found column (string): '$columnValue'."
            [void] $columns.Add($columnValue)
        }
        elseif ($columnValue -is [string[]]) {
            Write-Verbose "Found column (string array): '$($columnValue -join ', ')'."
            [void] $columns.AddRange($columnValue)
        }
        else {
            Write-Verbose "Column property is of type $($columnValue.GetType().Name) which is not handled. Skipping."
        }

        # If there are child nodes, process them recursively
        if ($node.ChildNodes -and $node.ChildNodes.Count -gt 0) {
            Write-Verbose "Node has $($node.ChildNodes.Count) child node(s). Recursing into child nodes..."
            $childColumns = Get-TriggerColumns -FilterNodes $node.ChildNodes
            if ($childColumns) {
                Write-Verbose "Adding child columns: '$($childColumns -join ', ')'."
                [void] $columns.AddRange($childColumns)
            }
        }
    }

    # Remove any empty strings, sort the list uniquely, and return the array
    $uniqueColumns = $columns.ToArray() | Sort-Object -Unique | Where-Object { $_ -ne "" }
    Write-Verbose "Unique columns found: '$($uniqueColumns -join ', ')'."
    return $uniqueColumns
}