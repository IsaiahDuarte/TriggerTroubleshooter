function Get-MatchingProcessCondition {
    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER RootNode
        
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $RootNode
    )
    
    try {
        # We don't need to do any validation. 
        $boundaryCheck = {
            param($Data, [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $SanitizedRoot)
            return , [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot
        }
        
        $defaults = @{ Name = 'sName' }
        
        return , (New-NodeDataTemplate `
                -RootNode $RootNode `
                -ColumnsToKeep @('sName') `
                -BoundaryCheck $boundaryCheck `
                -Defaults $defaults)
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingProcessCondition: $($_.Exception.Message)"
        throw
    }
}