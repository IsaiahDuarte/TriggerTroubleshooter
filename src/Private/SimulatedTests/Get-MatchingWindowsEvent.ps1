function Get-MatchingWindowsEvent {
    <#
    .SYNOPSIS
        Constructs a Windows Event object from a trigger node.
    
    .DESCRIPTION
        This function sanitizes a trigger node by removing regex-based subnodes,
        builds constraints from the result, populates a Windows Event PSCustomObject,
        applies default settings, and forces a Source value.
    
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
    
    Write-TriggerTroubleshooterLog "Sanitizing trigger node..."
    $sanitizedRoot = Format-SimulationNode -Node $RootNode -Columns @('Category', 'EntryType', 'EventID', 'Log', 'Message', 'Source')
    if (-not $sanitizedRoot) {
        Write-Warning "After removing regex nodes, no triggers remain. Returning null."
        return $null
    }
    
    Write-TriggerTroubleshooterLog "Building constraints from sanitized node..."
    try {
        $constraints = Get-ConstraintsForNode -Node $sanitizedRoot
    }
    catch {
        Write-Warning "Could not build constraints: $($_.Exception.Message)"
        return $null
    }
    
    Write-TriggerTroubleshooterLog "Creating basic Windows Event object..."
    $result = [PSCustomObject]@{
        Category  = ''
        EntryType = ''
        EventID   = 0
        Log       = ''
        Message   = ''
        Source    = ''
    }
    
    Write-TriggerTroubleshooterLog "Applying constraints..."
    foreach ($key in $constraints.Keys) {
        if ($result.PSObject.Properties.Name -contains $key) {
            # Use -Force to update an existing property if needed
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key] -Force
        }
        else {
            $result | Add-Member -NotePropertyName $key -NotePropertyValue $constraints[$key]
        }
    }
    
    Write-TriggerTroubleshooterLog "Setting default values for missing columns..."
    if (-not $result.Log) { $result.Log = 'Application' }
    if (-not $result.Message) { $result.Message = 'Auto-generated test event' }
    if (-not $result.EntryType) { $result.EntryType = 'Information' }
    if (-not $result.Category) { $result.Category = 'None' }
    
    $source = "TriggerTroubleshooter-" + $result.Log
    Write-TriggerTroubleshooterLog "Setting forced Source to '$source'..."

    $sanitizedRoot.ChildNodes.ExpressionDescriptor |
    Where-Object { $_.Column -eq 'Source' } |
    ForEach-Object { $_.Value = $source }
    $result.Source = $source
            
    Write-TriggerTroubleshooterLog "Removing empty child nodes recursively..."
    $sanitizedRoot = Remove-EmptyNodes -Node $sanitizedRoot
    
    Write-TriggerTroubleshooterLog "Returning event object and sanitized node."
    return [PSCustomObject]@{
        Data = $result
        Node  = $sanitizedRoot
    }
}