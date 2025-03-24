function Remove-EmptyNodes {
    <#
    .SYNOPSIS
        Recursively removes any child nodes that lack an ExpressionDescriptor and have no children.
        
    .DESCRIPTION
        This function inspects the passed-in node and its ChildNodes property, and for every child node
        that either does not have the ExpressionDescriptor property or its ExpressionDescriptor is blank,
        and it has no further child nodes, the child node is removed. The function processes all levels recursively.
     
        At the end, the modified node is returned.
    
    .PARAMETER Node
        The node object to process. This object must have a ChildNodes property which is a collection.
    
    .EXAMPLE
        $cleanNode = Remove-EmptyNodes -Node $myNode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $Node
    )

    if ($Node -and $Node.ChildNodes -and $Node.ChildNodes.Count -gt 0) {
        for ($i = $Node.ChildNodes.Count - 1; $i -ge 0; $i--) {
            $child = $Node.ChildNodes[$i]
            
            # Recurse into child nodes.
            Remove-EmptyNodes -Node $child
            
            $hasExpressionDescriptor = $false
            if ($child.PSObject.Properties['ExpressionDescriptor']) {
                if ($child.ExpressionDescriptor) {
                    $hasExpressionDescriptor = $true
                }
            }
            
            if (-not $hasExpressionDescriptor -and (-not $child.ChildNodes -or $child.ChildNodes.Count -eq 0)) {
                $Node.ChildNodes.RemoveAt($i)
            }
        }
    }
    return $Node
}