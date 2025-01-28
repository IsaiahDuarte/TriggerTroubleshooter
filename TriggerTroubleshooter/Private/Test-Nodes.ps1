function Test-Nodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array] $nodes,

        [Parameter(Mandatory=$true)]
        [object] $data,

        [Parameter(Mandatory=$true)]
        [ref]$ExpressionTree
    )

    $resultNode = $null
    for ($i = 0; $i -lt $nodes.Count; $i++) {
        $node = $nodes[$i]
        $childExpressionTree = $null
        $nodeResult = Test-Node -node $node -data $data -ExpressionTree ([ref]$childExpressionTree)

        if ($node.IsNegation) {
            $nodeResult = -not $nodeResult
            $childExpressionTree = [ExpressionNode]::new('Not', $childExpressionTree, $null, $nodeResult)
        }

        if ($null -eq $resultNode) {
            $resultNode = $childExpressionTree
        } else {
            $logicalOperator = $node.LogicalOperator
            $combinedResult = $null
            if ($logicalOperator -eq 'And') {
                $combinedResult = $resultNode.Result -and $childExpressionTree.Result
            } elseif ($logicalOperator -eq 'Or') {
                $combinedResult = $resultNode.Result -or $childExpressionTree.Result
            } else {
                throw "Unknown LogicalOperator: $logicalOperator"
            }
            $resultNode = [ExpressionNode]::new($logicalOperator, $resultNode, $childExpressionTree, $combinedResult)
        }
    }

    $ExpressionTree.Value = $resultNode

    return $resultNode.Result
}