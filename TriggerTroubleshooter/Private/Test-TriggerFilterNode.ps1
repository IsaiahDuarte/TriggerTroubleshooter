function Test-TriggerFilterNode {
    param (
        [Parameter(Mandatory)]
        $Node,

        [Parameter(Mandatory)]
        $Record
    )

    Write-Verbose "Evaluating node..."

    $result = [PSCustomObject]@{
        ExpressionDescriptor = $Node.ExpressionDescriptor
        IsNegation           = $Node.IsNegation
        LogicalOperator      = $Node.LogicalOperator.ToString()
        EvaluationResult     = $null
        Details              = $null
        ChildNodes           = @()
    }

    $currentResult = $null
    if ($null -ne $Node.ExpressionDescriptor) {
        $expr        = $Node.ExpressionDescriptor
        $column      = $expr.Column
        $value       = $expr.Value
        $compOp      = $expr.ComparisonOperator.ToString()
        $isRegex     = $expr.IsRegex
        $recordValue = $Record.$column

        Write-Verbose "Evaluating ExpressionDescriptor with column: $column, value: $value, ComparisonOperator: $compOp, isRegex: $isRegex"

        if ($compOp -eq 'Equal' -and $value -like '*`**') {
            $compOp = 'Like'
        }

        Write-Verbose "ComparisonOperator resolved to: $compOp"

        switch ($compOp) {
            'Equal' {
                if ($isRegex) {
                    $comparisonResult = $recordValue -match $value
                    $comparisonUsed   = "-match"
                } else {
                    $comparisonResult = $recordValue -eq $value
                    $comparisonUsed   = "-eq"
                }
            }
            'Like' {
                $comparisonResult = $recordValue -like $value
                $comparisonUsed   = "-like"
            }
            'NotEqual' {
                if ($isRegex) {
                    $comparisonResult = -not ($recordValue -match $value)
                    $comparisonUsed   = "-notmatch"
                } else {
                    $comparisonResult = $recordValue -ne $value
                    $comparisonUsed   = "-ne"
                }
            }
            'LessThan' {
                $comparisonResult = [double]$recordValue -lt [double]$value
                $comparisonUsed   = "-lt"
            }
            'LessThanOrEqual' {
                $comparisonResult = [double]$recordValue -le [double]$value
                $comparisonUsed   = "-le"
            }
            'GreaterThan' {
                $comparisonResult = [double]$recordValue -gt [double]$value
                $comparisonUsed   = "-gt"
            }
            'GreaterThanOrEqual' {
                $comparisonResult = [double]$recordValue -ge [double]$value
                $comparisonUsed   = "-ge"
            }
            'Contains' {
                $comparisonResult = $recordValue -like "*$value*"
                $comparisonUsed   = "-like"
            }
            'StartsWith' {
                $comparisonResult = $recordValue -like "$value*"
                $comparisonUsed   = "-like"
            }
            'EndsWith' {
                $comparisonResult = $recordValue -like "*$value"
                $comparisonUsed   = "-like"
            }
            default {
                throw "Unsupported ComparisonOperator: $compOp"
            }
        }

        $exprResult = $comparisonResult

        if ($Node.IsNegation) {
            $exprResult = -not $exprResult
        }

        $result.Details = @{
            RecordValue      = $recordValue
            ComparisonUsed   = $comparisonUsed
            ComparisonResult = $comparisonResult
        }

        $currentResult = $exprResult
    }

    if ($null -ne $Node.ChildNodes -and $Node.ChildNodes.Count -gt 0) {
        Write-Verbose "Processing child nodes..."

        # Initialize accumulated result with currentResult or the first child's result
        $accumulatedResult = $currentResult

        for ($i = 0; $i -lt $Node.ChildNodes.Count; $i++) {
            $child = $Node.ChildNodes[$i]
            $childResult = Test-TriggerFilterNode -Node $child -Record $Record
            $result.ChildNodes += $childResult

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

    if ($Node.IsNegation) {
        $accumulatedResult = -not $accumulatedResult
    }

    $result.EvaluationResult = $accumulatedResult

    Write-Verbose "Node evaluation result: $($result.EvaluationResult)"

    return $result
}