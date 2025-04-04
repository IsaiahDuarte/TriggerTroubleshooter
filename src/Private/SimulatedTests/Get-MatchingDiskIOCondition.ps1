function Get-MatchingDiskIOCondition {
    <#
    .SYNOPSIS
        Applies IO constraints to a trigger node.
        
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
            # List the disk columns to check
            $diskColumns = 'DiskKBps', 'DiskReadKBps', 'DiskWriteKBps'
            foreach ($col in $diskColumns) {
                if ($Data.PSObject.Properties[$col]) {
                    $value = $Data.$col
                    $dummy = 0
                    if (-not ([int]::TryParse($value, [ref] $dummy))) {
                        throw "Invalid value for $col, must be an integer."
                    }
                    
                    if ($Data.$col -gt 5000) {
                        $Data.$col = 5000
                        $SanitizedRoot.ChildNodes.ExpressionDescriptor |
                        Where-Object { $_.Column -eq $col } |
                        ForEach-Object { $_.Value = 5000 }
                    }
                }
            }
            # Force type with comma
            return , [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot
        }
        
        $defaults = @{ DiskKBps = 0; DiskReadKBps = 0; DiskWriteKBps = 0 }
        return , (New-NodeDataTemplate `
                -RootNode $RootNode `
                -ColumnsToKeep @('DiskKBps', 'DiskReadKBps', 'DiskWriteKBps') `
                -BoundaryCheck $boundaryCheck `
                -Defaults $defaults)
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingDiskIOCondition: $($_.Exception.Message)"
        throw
    }
}