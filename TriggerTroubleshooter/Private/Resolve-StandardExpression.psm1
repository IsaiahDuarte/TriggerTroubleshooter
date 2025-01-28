<#
    .SYNOPSIS
    Performs standard comparisons between two values using specified operators.

    .DESCRIPTION
    The Resolve-StandardExpression function evaluates two values using a specified comparison operator. The function supports various operators for standard comparisons including equality, inequality, and relational comparisons. It automatically determines and converts numeric strings to numbers when possible.
    
    .PARAMETER value
    The main value to be compared. This can be any object suitable for comparison operations.
    
    .PARAMETER comparisonValue
    The value against which the main value is compared. This can be any object suitable for comparison operations.
    
    .PARAMETER comparisonOperator
    The operator that defines the type of comparison: 'Equal', 'Like', 'NotEqual', 'GreaterThan', 'GreaterThanOrEqual', 'LessThan', or 'LessThanOrEqual'.

    .EXAMPLE

    .NOTES
    This is a helper function for Resolve-Expression. It is used within Resolve-Expression for non-regex evaluations.
#>
function Resolve-StandardExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object] $value,

        [Parameter(Mandatory=$true)]
        [object] $comparisonValue,

        [Parameter(Mandatory=$true)]
        [object] $comparisonOperator
    )

    $parsedValue = $null
    $valueIsNumeric = [double]::TryParse($value, [ref]$parsedValue)

    if ($valueIsNumeric) {
        $valueType = $parsedValue
    } else {
        $valueType = $value
    }

    $parsedComparisonValue = $null
    $comparisonValueIsNumeric = [double]::TryParse($comparisonValue, [ref]$parsedComparisonValue)

    if ($comparisonValueIsNumeric) {
        $comparisonValueType = $parsedComparisonValue
    } else {
        $comparisonValueType = $comparisonValue
    }

    if($comparisonValueType -like '*`**') {
        $comparisonOperator = 'Like'
    }

    switch ($comparisonOperator) {
        'Equal'                { return $valueType -eq $comparisonValueType }
        'Like'                 { return $valueType -like $comparisonValueType }
        'NotEqual'             { return $valueType -ne $comparisonValueType }
        'GreaterThan'          { return $valueType -gt $comparisonValueType }
        'GreaterThanOrEqual'   { return $valueType -ge $comparisonValueType }
        'LessThan'             { return $valueType -lt $comparisonValueType }
        'LessThanOrEqual'      { return $valueType -le $comparisonValueType }
        default                { throw "Unknown comparison operator: $comparisonOperator"; return $false }
    }
}