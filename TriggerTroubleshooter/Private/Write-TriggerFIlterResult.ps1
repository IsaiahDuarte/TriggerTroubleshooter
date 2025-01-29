function Write-TriggerFilterResult {
    param(
        [Parameter(Mandatory)]
        [array]$Nodes,
        [int]$IndentLevel = 0,
        [string]$PrefixOperator = ''
    )

    foreach ($Node in $Nodes) {
        $indent = (' ' * 4) * $IndentLevel

        if ($Node.EvaluationResult -eq $true) {
            $color = 'Green'
            $resultSymbol = '[TRUE ]'
        } else {
            $color = 'Red'
            $resultSymbol = '[FALSE]'
        }

        if ($Node.IsNegation) {
            $notStr = 'Not '
        } else {
            $notStr = ''
        }

        $prefix = ''
        if ($PrefixOperator -ne '') {
            $prefix = "$PrefixOperator "
        }

        if ($null -ne $Node.ExpressionDescriptor) {
            $expr    = $Node.ExpressionDescriptor
            $column  = $expr.Column
            $value   = $expr.Value
            $compOp  = $expr.ComparisonOperator.ToString()

            $conditionStr = "$notStr`'$column`' $compOp `'$value`'"

            $details = ''
            if ($null -ne $Node.Details) {
                $details = "(Value: $($Node.Details.RecordValue), Operator: $($Node.Details.ComparisonUsed))"
            }

            Write-Host "$indent$prefix- Condition: $conditionStr $details $resultSymbol" -ForegroundColor $color
        }

        if ($null -ne $Node.ChildNodes -and $Node.ChildNodes.Count -gt 0) {

            if ($null -eq $Node.ExpressionDescriptor) {
                Write-Host "$indent$prefix($($Node.LogicalOperator)) $resultSymbol" -ForegroundColor $color
            }

            for ($i = 0; $i -lt $Node.ChildNodes.Count; $i++) {
                $child = $Node.ChildNodes[$i]
                $childOperator = ''
                if ($i -gt 0) {
                    $childOperator = $child.LogicalOperator
                }
                Write-TriggerFilterResult -Nodes @($child) -IndentLevel ($IndentLevel + 1) -PrefixOperator $childOperator
            }
        }
    }
}