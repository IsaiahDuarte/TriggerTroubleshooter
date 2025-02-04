function Test-TriggerFilterNode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $Node,

        [Parameter(Mandatory=$true)]
        [object] $Record
    )

    $nullProps = $object.PSObject.Properties | Where-Object { $null -eq $_.Value }
    if ($nullProps) {
        $nullProps | ForEach-Object { Write-Warning "Null property: $($_.Name)";  }
    }

        
    Write-Verbose "Evaluating node..."

    $result = [TriggerFilterResult]::New()
    $result.ExpressionDescriptor = $Node.ExpressionDescriptor
    $result.IsNegation           = $Node.IsNegation
    $result.LogicalOperator      = $Node.LogicalOperator.ToString()

    $currentResult = $null
    if ($null -ne $Node.ExpressionDescriptor) {

        $expr        = $Node.ExpressionDescriptor
        $column      = $expr.Column
        $value       = $expr.Value
        $compOp      = $expr.ComparisonOperator.ToString()
        $isRegex     = $expr.IsRegex
        $recordValue = $Record.$column

        Write-Verbose "Evaluating ExpressionDescriptor with column: $column, value: $value, ComparisonOperator: $compOp, isRegex: $isRegex"
        $comparison = Test-Comparison -compOp $compOp -recordValue $recordValue -value $value -IsNegation $Node.IsNegation -IsRegex $isRegex
        $exprResult = $comparison.comparisonResult

        $result.Details = [TriggerDataResult]::New(
            $recordValue,
            $comparison.comparisonUsed,
            $comparison.comparisonResult,
            $record.Key
        )

        $currentResult = $exprResult
    }

    if ($null -ne $Node.ChildNodes -and $Node.ChildNodes.Count -gt 0 ) {

        Write-Verbose "Processing child nodes..."
        $accumulatedResult = $currentResult

        for ($i = 0; $i -lt $Node.ChildNodes.Count; $i++) {
            $child = $Node.ChildNodes[$i]
            if($null -eq $child) { continue }
            $childResult = Test-TriggerFilterNode -Node $child -Record $Record
            [void] $result.ChildNodes.Add($childResult)

            if ($i -eq 0 -and $null -eq $accumulatedResult) {
                $accumulatedResult = $childResult.EvaluationResult
            } else {
                $operator = $child.LogicalOperator

                if ([string]::IsNullOrEmpty($operator)) {
                    throw "Child node at position $i is missing LogicalOperator."
                }

                switch ($operator) {
                    'And' {
                        $accumulatedResult = $accumulatedResult -and $childResult.EvaluationResult
                    }
                    'Or' {
                        $accumulatedResult = $accumulatedResult -or $childResult.EvaluationResult
                    }
                    default {
                        throw "Unknown LogicalOperator: $operator"
                    }
                }
            }
        }
    } else {
        $accumulatedResult = $currentResult
    }

    $result.EvaluationResult = $accumulatedResult

    Write-Verbose "Node evaluation result: $($result.EvaluationResult)"

    return $result
}