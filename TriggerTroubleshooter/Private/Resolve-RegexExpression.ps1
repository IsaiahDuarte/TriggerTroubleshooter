<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER value

    .PARAMETER comparisonValue

    .PARAMETER comparisonOperator

    .EXAMPLE

    .NOTES
#>
function Resolve-RegexExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object] $value,

        [Parameter(Mandatory=$true)]
        [object] $comparisonValue,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Equal', 'NotEqual')]
        [string] $comparisonOperator,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )

    switch ($comparisonOperator) {
        'Equal'      {
            $result = [bool]($value -match $comparisonValue)
        }
        'NotEqual'   {
            $result = -not ([bool]($value -match $comparisonValue))
        }
    }
    $ComparisonDataList.Value.Add([ComparisonData]::new($value, $comparisonOperator, $comparisonValue, $result))
    return $result
}