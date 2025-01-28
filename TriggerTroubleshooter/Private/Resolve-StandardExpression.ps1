function Resolve-StandardExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $value,

        [Parameter(Mandatory = $true)]
        [object] $comparisonValue,

        [Parameter(Mandatory = $true)]
        [string] $comparisonOperator
    )

    $parsedValue = $null
    $parsedComparisonValue = $null

    if ([double]::TryParse($value.ToString(), [ref]$parsedValue)) {
        $value = $parsedValue
    }

    if ([double]::TryParse($comparisonValue.ToString(), [ref]$parsedComparisonValue)) {
        $comparisonValue = $parsedComparisonValue
    }

    if($comparisonValue -like '*`**') {
        $comparisonOperator = 'Like'
    }
    
    switch ($comparisonOperator) {
        'Equal'                { $result = $value -eq $comparisonValue }
        'Like'                 { $result = $value -like $comparisonValue }
        'NotEqual'             { $result = $value -ne $comparisonValue }
        'GreaterThan'          { $result = $value -gt $comparisonValue }
        'GreaterThanOrEqual'   { $result = $value -ge $comparisonValue }
        'LessThan'             { $result = $value -lt $comparisonValue }
        'LessThanOrEqual'      { $result = $value -le $comparisonValue }
        default                { 
            throw "Unknown comparison operator: $comparisonOperator" 
        }
    }

    $expressionTree = [ExpressionNode]::new($comparisonOperator, $value, $comparisonValue, $result)

    return @{
        Result = $result
        ExpressionTree = $expressionTree
    }
}