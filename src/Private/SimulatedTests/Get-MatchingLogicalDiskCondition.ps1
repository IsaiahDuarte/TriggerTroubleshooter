function Get-MatchingLogicalDiskCondition {
    <#
    .SYNOPSIS
        Applies LogicalDisk constraints to a trigger node.
        
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
        Write-TriggerTroubleshooterLog "Sanitizing trigger node..."
        $sanitizedRoot = Format-SimulationNode -Node $RootNode -Columns @('FreeSpacePercentage')
        if (-not $sanitizedRoot) {
            Write-Warning "No triggers remain after sanitization."
            return $null
        }
    
        Write-TriggerTroubleshooterLog "Building constraints from sanitized node..."
        $constraints = Get-ConstraintsForNode -Node $sanitizedRoot
        
        $result = [PSCustomObject]@{ FreeSpacePercentage = 0 }
    
        Write-TriggerTroubleshooterLog "Applying constraints..."
        foreach ($key in $constraints.Keys) {
            Write-TriggerTroubleshooterLog "Adding constraint for '$key'"
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key] -Force
        }
        
        $isThere = $false
        $isThere = [int]::TryParse($result.FreeSpacePercentage, [ref] $isThere)
        if (!$isThere) { throw "Trigger is missing FreeSpacePercentage" }

        # We cap to 10 just in case
        if ($result.FreeSpacePercentage -lt 10) {
            Write-TriggerTroubleshooterLog "FreeSpacePercentage value ($($result.FreeSpacePercentage)) exceeds 10%. Capping to 10%."
            $result.FreeSpacePercentage = 10
            $sanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'FreeSpacePercentage' } |
                ForEach-Object { $_.Value = 10 }
        }
        
        Write-TriggerTroubleshooterLog "Removing empty child nodes recursively..."
        $sanitizedRoot = Remove-EmptyNodes -Node $sanitizedRoot

        Write-TriggerTroubleshooterLog "Returning event object and sanitized node."
        return [PSCustomObject]@{
            Data = $result
            Node = $sanitizedRoot
        }
    }
    catch {
        Write-TriggerTroubleshooterLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingLogicalDiskCondition: $($_.Exception.Message)"
        throw
    }
}