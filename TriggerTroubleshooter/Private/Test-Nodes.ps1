<#}

    .SYNOPSIS
    Evaluates multiple nodes and resolves logical expressions based on their properties.

    .DESCRIPTION
    The Test-Nodes function iterates over a collection of nodes, evaluating each one's condition using the Test-Node function. It combines the results using logical operators defined in each node, supporting both "And" and "Or" logic, and applies negation if specified.

    .PARAMETER nodes
    An array of nodes, each containing information about what operation to perform and how to combine results with logical operators.

    .PARAMETER data
    The data object used for evaluation within each node. This typically includes the properties referenced by each node's expression.

    .EXAMPLE

    .NOTES
    This function is intended to be part of a larger evaluation system, relying on sub-functions like Test-Node to evaluate individual nodes.
#>
function Test-Nodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array] $nodes,

        [Parameter(Mandatory=$true)]
        [object] $data 
    )

    $result = $null
    for ($i = 0; $i -lt $nodes.Count; $i++) {
        $node = $nodes[$i]
        $nodeResult = Test-Node -node $node -data $data

        if ($node.IsNegation) {
            $nodeResult = -not $nodeResult
        }

        if ($null -eq $result) {
            $result = $nodeResult
        } else {
            $logicalOperator = $node.LogicalOperator
            if ($logicalOperator -eq 'And') {
                $result = $result -and $nodeResult
                if (-not $result) { break }
            } elseif ($logicalOperator -eq 'Or') {
                $result = $result -or $nodeResult
                if ($result) { break }
            } else {
                throw "Unknown LogicalOperator: $logicalOperator"
                $result = $false
                break
            }
        }
    }
    return $result
}