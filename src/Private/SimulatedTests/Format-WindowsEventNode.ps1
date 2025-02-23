function Format-WindowsEventNode {
    <#
        .SYNOPSIS
            Cleans a Windows Event Filter node by removing any nodes that use Regex.

        .DESCRIPTION
            This function inspects a TriggerFilterNode object and removes it if its
            ExpressionDescriptor uses Regex or if its column is not in the allowed list.
            It recurses through child nodes to perform the same clean-up.

        .PARAMETER Node
            A TriggerFilterNode object to be processed. This parameter is mandatory.

        .EXAMPLE
            Format-WindowsEventNode -Node $filterNode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $Node
    )

    try {
        Write-Verbose "Starting node formatting."
        
        if (-not $Node) {
            Write-Verbose "Node is null or empty. Exiting function."
            return $null
        }

        # Check if ExpressionDescriptor exists and if it's invalid
        if ($Node.ExpressionDescriptor) {
            $allowedColumns = @('Category', 'EntryType', 'EventID', 'Log', 'Message', 'Source')
            if ($Node.ExpressionDescriptor.IsRegex -or -not ($allowedColumns -contains $Node.ExpressionDescriptor.Column)) {
                Write-Verbose "ExpressionDescriptor is either Regex or not in allowed columns. Removing node."
                return $null
            }
        }
        
        # Recurse through child nodes and build a new list without invalid nodes.
        $cleanChildren = [System.Collections.Generic.List[ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]]::New()
        foreach ($child in $Node.ChildNodes) {
            Write-Verbose "Processing a child node."
            $processedChild = Format-WindowsEventNode -Node $child
            if ($processedChild) {
                $cleanChildren.Add($processedChild)
            }
        }
        $Node.ChildNodes = $cleanChildren

        Write-Verbose "Finished processing node."
        return , $Node
    }
    catch {
        Write-Error "Error in Format-WindowsEventNode: $($_.Exception.Message)"
        throw
    }
}