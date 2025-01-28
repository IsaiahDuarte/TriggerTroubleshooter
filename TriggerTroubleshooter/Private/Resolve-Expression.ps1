<#
    .SYNOPSIS
    Resolves and evaluates expressions based on specified comparison operators, supporting both standard and regular expression comparisons.

    .DESCRIPTION
    The Resolve-Expression function evaluates whether a provided value matches a comparison value using a specified comparison operator. The function supports the use of both regex and standard comparison methods, allowing for various expression evaluations including equality, inequalities, and pattern matching.

    .PARAMETER value
    The value to be evaluated. This could be a number, string, or any object that the comparison would apply to.

    .PARAMETER comparisonValue
    The value against which the main value is compared. This should be of a compatible type with the 'value' to ensure valid comparisons.

    .PARAMETER comparisonOperator
    The operator defining the type of comparison to perform. Valid options are 'Equal', 'NotEqual', 'Like', 'GreaterThan', 'GreaterThanOrEqual', 'LessThan', and 'LessThanOrEqual'.

    .PARAMETER isRegex
    A boolean indicating whether to use regex evaluation for the comparison.
    If true, Resolve-RegexExpression will be used; otherwise, Resolve-StandardExpression.

    .EXAMPLE

    .NOTES
    This function was made to test dynamic conditions based on evaluated expressions.
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
        [bool] $isRegex
    )

    $splat = @{
        value = $value
        comparisonValue = $comparisonValue
        comparisonOperator = $comparisonOperator
    }

    if ($isRegex) {
        return Resolve-RegexExpression @splat
    } else {
        return Resolve-StandardExpression @splat
    }
}