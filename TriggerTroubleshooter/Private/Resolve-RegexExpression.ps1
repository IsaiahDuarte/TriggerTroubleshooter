<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER value

    .PARAMETER comparisonValue

    .PARAMETER comparisonOperator

    .EXAMPLE

    .NOTES
#>
unction Resolve-RegexExpression {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object] $value,

        [Parameter(Mandatory=$true)]
        [object] $comparisonValue,

        [Parameter(Mandatory=$true)]
        [string] $comparisonOperator,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )

    switch ($comparisonOperator) {
        'Equal'      {
            $result = [bool]($value -match $comparisonValue)
            $ComparisonDataList.Value.Add([ComparisonData]::new($value, $comparisonOperator, $comparisonValue, $result))
            return $result
        }
        'NotEqual'   {
            $result = -not ([bool]($value -match $comparisonValue))
            $ComparisonDataList.Value.Add([ComparisonData]::new($value, $comparisonOperator, $comparisonValue, $result))
            return $result
        }
        default      { throw "Unsupported comparison operator for regex: $comparisonOperator" }
    }
}