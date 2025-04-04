function Get-MatchingCPUCondition {
    <#
    .SYNOPSIS
        Applies CPU constraints to a trigger node.
        
    .DESCRIPTION
        This function validates and sanitizes the CPU value in the trigger node.
        It ensures that a CPU value is provided and caps the value at 75 if necessary.
        
    .PARAMETER RootNode
        The trigger filter node to apply CPU constraints to.
        
    .EXAMPLE
        Get-MatchingCPUCondition -RootNode $myTriggerNode
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $RootNode
    )
    
    try {
        # Check that ensures CPU is a valid integer and does not exceed 75.
        $boundaryCheck = {
            param($Data, [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $SanitizedRoot)
            $isValid = [int]::TryParse($Data.CPU, [ref] $null)
            if (-not $isValid) { throw "Trigger missing CPU" }
            if ($Data.CPU -gt 75) {
                $Data.CPU = 75
                $SanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'CPU' } |
                ForEach-Object { $_.Value = 75 }
            }
            # Force type with comma
            return , [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot
        }
        
        $defaults = @{ CPU = 0 }
        
        return , (New-NodeDataTemplate `
                -RootNode $RootNode `
                -ColumnsToKeep @('CPU') `
                -BoundaryCheck $boundaryCheck `
                -Defaults $defaults)
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingCPUCondition: $($_.Exception.Message)"
        throw
    }
}