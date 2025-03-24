function Format-SimulationNode {
    <#
        .SYNOPSIS
            Sanitizes a TriggerFilterNode to specific columns.

        .DESCRIPTION
            Sanitizes a TriggerFilterNode to specific columns by removing columns that cannot
            be simulated.

        .PARAMETER Node
            A TriggerFilterNode object to be processed. This parameter is mandatory.

        .EXAMPLE
            Format-SimulationNode -Node $node -Columns @('Category', 'EntryType', 'EventID', 'Log', 'Message', 'Source')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $Node,

        [Parameter(Mandatory = $true)]
        [string[]] $Columns
    )

    try {
        Write-TriggerTroubleshooterLog "Starting node formatting."
        
        if (-not $Node) {
            Write-TriggerTroubleshooterLog "Node is null or empty. Exiting function."
            return $null
        }

        # Check if ExpressionDescriptor exists and if it's invalid
        if ($Node.ExpressionDescriptor) {
            if ($Node.ExpressionDescriptor.IsRegex -or -not ($Columns -contains $Node.ExpressionDescriptor.Column)) {
                Write-TriggerTroubleshooterLog "ExpressionDescriptor is either Regex or not in allowed columns. Removing node."
                return $null
            }
        }
        
        # Recurse through child nodes and build a new list without invalid nodes.
        $cleanChildren = [System.Collections.Generic.List[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]]::New()
        foreach ($child in $Node.ChildNodes) {
            Write-TriggerTroubleshooterLog "Processing a child node."
            $processedChild = Format-SimulationNode -Node $child -Columns $Columns
            if ($processedChild) {
                $cleanChildren.Add($processedChild)
            }
        }
        $Node.ChildNodes = $cleanChildren

        Write-TriggerTroubleshooterLog "Finished processing node."
        return , $Node
    }
    catch {
        Write-Error "Error in Format-WindowsEventNode: $($_.Exception.Message)"
        throw
    }
}