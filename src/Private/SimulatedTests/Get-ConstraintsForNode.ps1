function Get-ConstraintsForNode {
    <#
    .SYNOPSIS
        Builds a constraints hashtable for a filter node tree.
    
    .DESCRIPTION
        Recursively merges a node’s expression descriptor and its child nodes’ constraints using logical And/Or.
        For "And", conflicts result in an error; for "Or", constraints are merged if possible.
    
    .PARAMETER Node
        A TriggerFilterNode object containing an ExpressionDescriptor, IsNegation, LogicalOperator, and ChildNodes.
    
    .EXAMPLE
        Get-ConstraintsForNode -Node $myFilterNode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $Node
    )
    
    Write-TTLog "Processing node constraints."
    
    if (-not $Node) { return @{} }
    
    $baseConstraints = @{}
    
    if ($Node.ExpressionDescriptor) {
        $col = $Node.ExpressionDescriptor.Column
        try {
            Write-TTLog "Evaluating expression for column '$col'."
            $val = Get-ValueThatSatisfiesExpression -expr $Node.ExpressionDescriptor -isNegation $Node.IsNegation
            $baseConstraints[$col] = $val
        }
        catch {
            throw "Error building expression for column '$col': $($_.Exception.Message)"
        }
    }
    
    if (-not $Node.ChildNodes -or $Node.ChildNodes.Count -eq 0) { 
        Write-TTLog "No child nodes found; returning base constraints."
        return $baseConstraints 
    }
    
    foreach ($child in $Node.ChildNodes) {
        if (-not $child) { continue }
    
        Write-TTLog "Processing child node with LogicalOperator '$($child.LogicalOperator)'."
        $childConstraints = Get-ConstraintsForNode -Node $child
    
        switch ($child.LogicalOperator) {
            'And' {
                # Check for conflicts and merge constraints
                foreach ($key in $childConstraints.Keys) {
                    if ($baseConstraints.ContainsKey($key) -and ($baseConstraints[$key] -ne $childConstraints[$key])) {
                        throw "Conflict: cannot unify '$key' => '$($baseConstraints[$key])' with '$($childConstraints[$key])'."
                    }
                }
                foreach ($key in $childConstraints.Keys) {
                    $baseConstraints[$key] = $childConstraints[$key]
                }
                Write-TTLog "Merged child constraints with 'And'."
            }
            'Or' {
                $tempConstraints = $baseConstraints.Clone()
                $canUnify = $true
                foreach ($key in $childConstraints.Keys) {
                    if ($tempConstraints.ContainsKey($key) -and ($tempConstraints[$key] -ne $childConstraints[$key])) {
                        $canUnify = $false
                        break
                    }
                    $tempConstraints[$key] = $childConstraints[$key]
                }
                if ($canUnify) {
                    $baseConstraints = $tempConstraints
                    Write-TTLog "Merged child constraints with 'Or'."
                }
                else {
                    Write-TTLog "Skipped merging conflicting 'Or' constraints; keeping base constraints."
                }
            }
            default {
                throw "Unknown LogicalOperator: $($child.LogicalOperator)"
            }
        }
    }
    Write-TTLog "Returning merged constraints."
    return $baseConstraints
}