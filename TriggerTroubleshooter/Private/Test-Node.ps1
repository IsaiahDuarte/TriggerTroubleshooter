function Test-Node {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object] $node,
            
        [Parameter(Mandatory = $true)]
        [object] $data
    )

    Write-Verbose "Starting Test-Node for node."

    if ($node.ExpressionDescriptor) {
        $exp = $node.ExpressionDescriptor
        $column = $exp.Column

        $value = if ($data.PSObject.Properties.Name -contains $column) {
            $data.$column
        } else {
            $null
        }

        if ($null -eq $value) {
            $result = $false
            $expressionTree = [ExpressionNode]::new($exp.ComparisonOperator, $null, $exp.Value, $result)
        } else {
            $resolvedExpression = Resolve-Expression -value $value `
                                                 -comparisonValue $exp.Value `
                                                 -comparisonOperator $exp.ComparisonOperator `
                                                 -isRegex $exp.IsRegex
            $result = $resolvedExpression.Result
            $expressionTree = $resolvedExpression.ExpressionTree
        }
    } elseif ($node.ChildNodes -and $node.ChildNodes.Count -gt 0) {
        $resolvedNodes = Test-Nodes -nodes $node.ChildNodes -data $data
        $result = $resolvedNodes.Result
        $expressionTree = $resolvedNodes.ExpressionTree

        if ($node.IsNegation) {
            $result = -not $result
            $expressionTree = [ExpressionNode]::new('Not', $expressionTree, $null, $result)
        }
    } else {
        $result = $true
        $expressionTree = [ExpressionNode]::new('Default', $null, $null, $result)
    }

    return @{
        Result = $result
        ExpressionTree = $expressionTree
    }
}