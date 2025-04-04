function Get-MatchingWindowsEvent {
    <#
    .SYNOPSIS
        Constructs a Windows Event object from a trigger node.
    
    .DESCRIPTION
        This function sanitizes a trigger node, applies default values to missing columns,
        forces a specific Source value, and produces a sanitized node along with the event data.
    
    .PARAMETER RootNode
        A TriggerFilterNode object representing the initial trigger tree.
    
    .EXAMPLE
        Get-MatchingWindowsEvent -RootNode $triggerNode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $RootNode
    )
    
    try {
        $boundaryCheck = {
            param($Data, [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $SanitizedRoot)
            # Set defaults for missing properties
            if (-not $Data.Category) { $Data.Category = 'None' }
            if (-not $Data.EntryType) { $Data.EntryType = 'Information' }
            if (-not $Data.Log) { $Data.Log = 'Application' }
            if (-not $Data.Message) { $Data.Message = 'Auto-generated test event' }
            # Ensure EventID is int
            $Data.EventID = [int]$Data.EventID
            # Force the Source value
            $forcedSource = "TriggerTroubleshooter-" + $Data.Log
            $Data.Source = $forcedSource
            $SanitizedRoot.ChildNodes.ExpressionDescriptor |
            Where-Object { $_.Column -eq 'Source' } |
            ForEach-Object { $_.Value = $forcedSource }
            # Force type with comma
            return ,[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]$SanitizedRoot
        }
        
        $defaults = @{
            Category  = 'None'
            EntryType = 'Information'
            EventID   = 0
            Log       = 'Application'
            Message   = 'Auto-generated test event'
            Source    = ''
        }
        
        return , (New-NodeDataTemplate `
                -RootNode $RootNode `
                -ColumnsToKeep @('Category', 'EntryType', 'EventID', 'Log', 'Message', 'Source') `
                -BoundaryCheck $boundaryCheck `
                -Defaults $defaults)
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-MatchingWindowsEvent: $($_.Exception.Message)"
        throw
    }
}