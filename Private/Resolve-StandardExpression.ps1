<#
    .SYNOPSIS

    .DESCRIPTION
    
    .PARAMETER value
    
    .PARAMETER comparisonValue
    
    .PARAMETER comparisonOperator

    .EXAMPLE

    .NOTES
#>
function Resolve-StandardExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object] $value,

        [Parameter(Mandatory=$true)]
        [object] $comparisonValue,

        [Parameter(Mandatory=$true)]
        [object] $comparisonOperator,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )

    $parsedValue = $null
    $valueIsNumeric = [double]::TryParse($value, [ref]$parsedValue)

    if ($valueIsNumeric) {
        $value = $parsedValue
    }

    $parsedComparisonValue = $null
    $comparisonValueIsNumeric = [double]::TryParse($comparisonValue, [ref]$parsedComparisonValue)

    if ($comparisonValueIsNumeric) {
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
        default                { throw "Unknown comparison operator: $comparisonOperator" }
    }

    $ComparisonDataList.Value.Add([ComparisonData]::new($value, $comparisonOperator, $comparisonValue, $result))

    return $result
}