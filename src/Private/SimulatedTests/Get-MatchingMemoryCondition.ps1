function Get-MatchingMemoryCondition {
    <#
    .SYNOPSIS
        Applies memory constraints to a trigger node.
        
    .DESCRIPTION
        This function sanitizes a trigger node, builds constraints from it,
        and ensures that the MemoryInUse value does not exceed 90. It returns an object
        containing the constraint data and the sanitized node.

    .PARAMETER RootNode
        A TriggerFilterNode object representing the initial trigger tree.

    .EXAMPLE
        Get-MatchingMemoryCondition -RootNode $triggerNode
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $RootNode
    )
    
    try {
        Write-TTLog "Sanitizing trigger node..."
        $sanitizedRoot = Format-SimulationNode -Node $RootNode -Columns @('MemoryInUse')
        if (-not $sanitizedRoot) {
            Write-Warning "No triggers remain after sanitization."
            return $null
        }
    
        Write-TTLog "Building constraints from sanitized node..."
        $constraints = Get-ConstraintsForNode -Node $sanitizedRoot
        
        # Create a result object with default MemoryInUse.
        $result = [PSCustomObject]@{ MemoryInUse = 0 }
    
        Write-TTLog "Applying constraints..."
        foreach ($key in $constraints.Keys) {
            Write-TTLog "Adding constraint for '$key'"
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key] -Force
        }
    
        $isThere = $false
        $isThere = [int]::TryParse($result.MemoryInUse, [ref] $isThere)
        if (!$isThere) { throw "Trigger is missing MemoryInUse" }
        
        # We cap to 90 in case TestLimit cant reach 90. Tested with 2GB VM
        if ($result.MemoryInUse -gt 90) {
            Write-TTLog "MemoryInUse value ($($result.MemoryInUse)) exceeds 90. Capping to 90."
            $result.MemoryInUse = 90
            $sanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'MemoryInUse' } |
                ForEach-Object { $_.Value = 90 }
        }
        
        Write-TTLog "Removing empty child nodes recursively..."
        $sanitizedRoot = Remove-EmptyNodes -Node $sanitizedRoot

        Write-TTLog "Returning event object and sanitized node."
        return [PSCustomObject]@{
            Data = $result
            Node = $sanitizedRoot
        }
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingMemoryCondition: $($_.Exception.Message)"
        throw
    }
}