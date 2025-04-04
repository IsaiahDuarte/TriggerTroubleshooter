function Get-MatchingDiskUsageCondition {
    <#
    .SYNOPSIS
        Applies DiskUsage constraints to a trigger node.
        
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
        $boundaryCheck = {
            param($Data, [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot)
            $isValid = [int]::TryParse($Data.FreeSpacePercentage, [ref]$null)
            if (-not $isValid) { throw "Trigger missing FreeSpacePercentage" }
            if ($Data.FreeSpacePercentage -lt 10) {
                $Data.FreeSpacePercentage = 10
                $sanitizedRoot.ChildNodes.ExpressionDescriptor |
                Where-Object { $_.Column -eq 'FreeSpacePercentage' } |
                ForEach-Object { $_.Value = 10 }
            }
            # Force type with comma
            return , [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot
        }
        
        $defaults = @{ FreeSpacePercentage = 0 }
        return , (New-NodeDataTemplate `
                -RootNode $RootNode `
                -ColumnsToKeep @('FreeSpacePercentage') `
                -BoundaryCheck $boundaryCheck `
                -Defaults $defaults)
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingDiskUsageCondition: $($_.Exception.Message)"
        throw
    }
}