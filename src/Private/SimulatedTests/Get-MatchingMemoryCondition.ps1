function Get-MatchingMemoryCondition {
    <#
    .SYNOPSIS
        Applies Memory constraints to a trigger node.
        
    .DESCRIPTION
        This function validates and sanitizes a trigger node by verifying that a MemoryInUse value 
        exists and that it does not exceed 90. If it does, it is capped 
        at 90 and the corresponding child node is updated.
        
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
        $boundaryCheck = {
            param($Data, [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $SanitizedRoot)
            $isValid = [int]::TryParse($Data.MemoryInUse, [ref] $null)
            if (-not $isValid) { throw "Trigger is missing MemoryInUse" }
            if ($Data.MemoryInUse -gt 90) {
                $Data.MemoryInUse = 90
                $SanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'MemoryInUse' } |
                ForEach-Object { $_.Value = 90 }
            }
            # Force type with comma
            return ,[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot
        }
        
        $defaults = @{ MemoryInUse = 0 }
        
        return , (New-NodeDataTemplate `
                -RootNode $RootNode `
                -ColumnsToKeep @('MemoryInUse') `
                -BoundaryCheck $boundaryCheck `
                -Defaults $defaults)
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingMemoryCondition: $($_.Exception.Message)"
        throw
    }
}