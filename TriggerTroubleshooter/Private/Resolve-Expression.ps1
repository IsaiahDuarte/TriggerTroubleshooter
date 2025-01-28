function Resolve-Expression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object] $value,

        [Parameter(Mandatory = $true)]
        [object] $comparisonValue,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Equal', 'NotEqual', 'Like', 'GreaterThan', 'GreaterThanOrEqual', 'LessThan', 'LessThanOrEqual')]
        [string] $comparisonOperator,

        [Parameter(Mandatory = $true)]
        [bool] $isRegex
    )

    if ($isRegex) {
        return Resolve-RegexExpression -value $value `
                                       -comparisonValue $comparisonValue `
                                       -comparisonOperator $comparisonOperator
    } else {
        return Resolve-StandardExpression -value $value `
                                          -comparisonValue $comparisonValue `
                                          -comparisonOperator $comparisonOperator
    }
}