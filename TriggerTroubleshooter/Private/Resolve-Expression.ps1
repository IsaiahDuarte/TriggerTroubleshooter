<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER value

    .PARAMETER comparisonValue

    .PARAMETER comparisonOperator

    .PARAMETER isRegex

    .EXAMPLE

    .NOTES
#>
function Resolve-Expression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object] $value,
        
        [Parameter(Mandatory=$true)]
        [object] $comparisonValue,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Equal', 'NotEqual', 'Like', 'GreaterThan', 'GreaterThanOrEqual', 'LessThan', 'LessThanOrEqual')]
        [string] $comparisonOperator,
        
        [Parameter(Mandatory=$true)]
        [bool] $isRegex,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )

    $splat = @{
        value = $value
        comparisonValue = $comparisonValue
        comparisonOperator = $comparisonOperator
        ComparisonDataList = $ComparisonDataList
    }

    if ($isRegex) {
        return Resolve-RegexExpression @splat
    } else {
        return Resolve-StandardExpression @splat
    }
}