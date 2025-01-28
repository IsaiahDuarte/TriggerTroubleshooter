function Resolve-RegexExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $value,

        [Parameter(Mandatory = $true)]
        [object] $comparisonValue,

        [Parameter(Mandatory = $true)]
        [string] $comparisonOperator
    )

    switch ($comparisonOperator) {
        'Equal' {
            $result = [bool]($value -match $comparisonValue)
        }
        'NotEqual' {
            $result = -not ([bool]($value -match $comparisonValue))
        }
        default {
            throw "Unsupported comparison operator for regex: $comparisonOperator"
        }
    }

    $expressionTree = [ExpressionNode]::new($comparisonOperator, $value, $comparisonValue, $result)

    return @{
        Result = $result
        ExpressionTree = $expressionTree
    }
}