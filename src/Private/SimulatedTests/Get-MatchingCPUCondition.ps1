function Get-MatchingCPUCondition {
    <#
    .SYNOPSIS
        Applies CPU constraints to a trigger node.
        
    .DESCRIPTION

    .PARAMETER RootNode

    .EXAMPLE
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $RootNode
    )
    
    try {
        Write-TTLog "Sanitizing trigger node..."
        $sanitizedRoot = Format-SimulationNode -Node $RootNode -Columns @('CPU')
        if (-not $sanitizedRoot) {
            Write-Warning "No triggers remain after sanitization."
            return $null
        }
    
        Write-TTLog "Building constraints from sanitized node..."
        $constraints = Get-ConstraintsForNode -Node $sanitizedRoot
        
        # Create a result object with default CPU.
        $result = [PSCustomObject]@{ CPU = 0 }
    
        Write-TTLog "Applying constraints..."
        foreach ($key in $constraints.Keys) {
            Write-TTLog "Adding constraint for '$key'"
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key] -Force
        }
        
        $isThere = $false
        $isThere = [int]::TryParse($result.CPU, [ref] $isThere)
        if (!$isThere) { throw "Trigger is missing CPU" }

        # We cap to 75 just in case
        if ($result.CPU -gt 75) {
            Write-TTLog "CPU value ($($result.CPU)) exceeds 75. Capping to 75."
            $result.CPU = 75
            $sanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'CPU' } |
                ForEach-Object { $_.Value = 75 }
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