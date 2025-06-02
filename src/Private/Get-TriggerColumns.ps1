function Get-TriggerColumns {
    <#
        .SYNOPSIS
            Extracts unique trigger column names from a list of filter nodes.
        .DESCRIPTION
            Iterates over a list of TriggerFilterNode objects, extracting the Column property from
            each node’s ExpressionDescriptor (if available) and recursively processing any child nodes.
        .PARAMETER FilterNodes
            A list of ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode objects.
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
            
            # Only extract column if the ExpressionDescriptor exists and has a Column property
            if ($node.ExpressionDescriptor) {
                if ($node.ExpressionDescriptor.PSObject.Properties['Column']) {
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
                }
                else {
                    Write-TTLog "ExpressionDescriptor exists but does not contain a 'Column' property."
                }
            }
            else {
                Write-TTLog "Node has null ExpressionDescriptor. It might be a container node."
            }
            
            # Always process any child nodes regardless of ExpressionDescriptor
            if ($node.ChildNodes -and $node.ChildNodes.Count -gt 0) {
                Write-TTLog "Processing $($node.ChildNodes.Count) child node(s)."
                $childColumns = Get-TriggerColumns -FilterNodes $node.ChildNodes
                if ($childColumns.count -gt 1) {
                    Write-TTLog ("Adding child columns: {0}." -f ($childColumns -join ', '))
                    [void] $columns.AddRange($childColumns)
                }
                elseif ($childColumns.count -eq 1) {
                    Write-TTLog ("Adding child columns: {0}." -f ($childColumns -join ', '))
                    [void] $columns.Add($childColumns)
                }
            }
        }
        
        [array] $uniqueColumns = $columns.ToArray() | Sort-Object -Unique
        Write-TTLog ("Returning unique columns: {0}." -f ($uniqueColumns -join ', '))
        
        return $uniqueColumns
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-TriggerColumns: $($_.Exception.Message)"
        throw
    }
}