function Test-Nodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $nodes,

        [Parameter(Mandatory = $true)]
        [object] $data
    )

    Write-Verbose "Starting Test-Nodes"

    if ($nodes.Count -eq 0) {
        $expressionTree = [ExpressionNode]::new('Default', $null, $null, $true)
        return @{
            Result = $true
            ExpressionTree = $expressionTree
        }
    }

    $resolvedNode = Test-Node -node $nodes[0] -data $data
    $accumulatedResult = $resolvedNode.Result
    $expressionTree = $resolvedNode.ExpressionTree

    for ($i = 1; $i -lt $nodes.Count; $i++) {
        $node = $nodes[$i]
        $resolvedNode = Test-Node -node $node -data $data
        $nodeResult = $resolvedNode.Result
        $nodeExpressionTree = $resolvedNode.ExpressionTree

        $logicalOperator = $node.LogicalOperator.ToString()

        $accumulatedResult = switch ($logicalOperator) {
            'And' { $accumulatedResult -and $nodeResult }
            'Or'  { $accumulatedResult -or $nodeResult }
            default { throw "Unknown LogicalOperator: $logicalOperator" }
        }

        $expressionTree = [ExpressionNode]::new($logicalOperator, $expressionTree, $nodeExpressionTree, $accumulatedResult)
    }

    return @{
        Result = $accumulatedResult
        ExpressionTree = $expressionTree
    }
}