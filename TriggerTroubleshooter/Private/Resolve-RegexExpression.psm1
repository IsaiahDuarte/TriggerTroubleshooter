<#
    .SYNOPSIS
    Evaluates a value against a comparison value using regular expression based operators.

    .DESCRIPTION
    The Resolve-RegexExpression function assesses two values using a regular expression to determine if they satisfy specified comparison criteria. It provides support for determining equality and inequality based on regex patterns.

    .PARAMETER value
    The main input value to be compared. This can be a string or any object that permits regex evaluation.

    .PARAMETER comparisonValue
    Represents the regex pattern or value against which the main value is compared.

    .PARAMETER comparisonOperator
    Specifies the type of comparison to carry out. Supported operators are 'Equal' and 'NotEqual' for regex evaluations.

    .EXAMPLE

    .NOTES
    This is a helper function for Resolve-Expression. It is used for handling regex-based comparisons.
#>
function Resolve-RegexExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object] $value,

        [Parameter(Mandatory=$true)]
        [object] $comparisonValue,

        [Parameter(Mandatory=$true)]
        [object] $comparisonOperator
    )

    switch ($comparisonOperator) {
        'Equal'      { return [bool]($value -match $comparisonValue) }
        'NotEqual'   { return -not ([bool]($value -match $comparisonValue)) }
        default      { throw "Unsupported comparison operator for regex: $comparisonOperator"}
    }
}