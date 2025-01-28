function Show-NodeResults {
    param (
        [Parameter(Mandatory=$true)]
        [ExpressionNode]$Node,

        [int]$Indent = 0
    )

    $indentation = (' ' * $Indent)
    if ($Node.NodeType -eq 'Comparison') {
        Write-Host "${indentation}Comparison: $($Node.Value) $($Node.Operator) $($Node.ComparisonValue) => $($Node.Result)"
    } elseif ($Node.NodeType -eq 'Logical') {
        Write-Host "${indentation}Logical: $($Node.Operator) => $($Node.Result)"
        if ($Node.Left) {
            Show-NodeResults -Node $Node.Left -Indent ($Indent + 2)
        }
        if ($Node.Right) {
            Show-NodeResults -Node $Node.Right -Indent ($Indent + 2)
        }
    } elseif ($Node.NodeType -eq 'Not') {
        Write-Host "${indentation}Not => $($Node.Result)"
        if ($Node.Left) {
            Show-NodeResults -Node $Node.Left -Indent ($Indent + 2)
        }
    }
}