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
        Write-Verbose "Sanitizing trigger node..."
        $sanitizedRoot = Format-SimulationNode -Node $RootNode -Columns @('CPU')
        if (-not $sanitizedRoot) {
            Write-Warning "No triggers remain after sanitization."
            return $null
        }
    
        Write-Verbose "Building constraints from sanitized node..."
        $constraints = Get-ConstraintsForNode -Node $sanitizedRoot
        
        # Create a result object with default CPU.
        $result = [PSCustomObject]@{ CPU = 0 }
    
        Write-Verbose "Applying constraints..."
        foreach ($key in $constraints.Keys) {
            Write-Verbose "Adding constraint for '$key'"
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key] -Force
        }
        
        $isThere = $false
        $isThere = [int]::TryParse($result.CPU, [ref] $isThere)
        if (!$isThere) { throw "Trigger is missing CPU" }

        # We cap to 75 just in case
        if ($result.CPU -gt 75) {
            Write-Verbose "CPU value ($($result.CPU)) exceeds 75. Capping to 75."
            $result.CPU = 75
            $sanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'CPU' } |
                ForEach-Object { $_.Value = 75 }
        }
    
        Write-Verbose "Returning event object and sanitized node."
        return [PSCustomObject]@{
            Data = $result
            Node = $sanitizedRoot
        }
    }
    catch {
        Write-Error "Error in Get-MatchingMemoryCondition: $($_.Exception.Message)"
        throw
    }
}