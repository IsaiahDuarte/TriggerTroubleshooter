<#
    .SYNOPSIS
    Evaluates a single node based on its defined expression descriptor or child nodes.

    .DESCRIPTION
    The Test-Node function evaluates a node by checking its expression descriptor if present, using the Resolve-Expression function for value comparison. If the node has child nodes, it delegates evaluation to Test-Nodes. If neither is present, it defaults to returning true.

    .PARAMETER node
    An individual node object containing an expression descriptor or child nodes for logical evaluation.

    .PARAMETER data
    The data object that contains properties for comparison against the node's expression if applicable.

    .EXAMPLE

    .NOTES
    This function is for evaluating individual nodes within a larger expression hierarchy.
#>
function Test-Node {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object] $node,
        
        [Parameter(Mandatory=$true)]
        [object] $data
    )

    if ($node.ExpressionDescriptor) {
        $exp = $node.ExpressionDescriptor
        $column = $exp.Column
        $value = $null

        if ($data.PSObject.Properties.Name -contains $column) {
            $value = $data.$column
        }

        $comparisonValue = $exp.Value
        $comparisonOperator = $exp.ComparisonOperator
        $isRegex = $exp.IsRegex

        if ($null -eq $value) {
            $result = $false
        } else {
            $result = Resolve-Expression -value $value -comparisonValue $comparisonValue -comparisonOperator $comparisonOperator -isRegex $isRegex
        }
    } elseif ($node.ChildNodes) {
        $result = Test-Nodes -nodes $node.ChildNodes -data $data
    } else {
        $result = $true
    }

    return $result
}