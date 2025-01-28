<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER node

    .PARAMETER data

    .EXAMPLE

    .NOTES
#>
function Test-Node {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object] $node,
        
        [Parameter(Mandatory=$true)]
        [object] $data,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )

    if ($node.ExpressionDescriptor) {
        $exp = $node.ExpressionDescriptor
        $column = $exp.Column
        $value = $null

        if ($data.PSObject.Properties.Name -contains $column) {
            $value = $data.$column
        }

        $comparisonValue = $exp.Value
        $comparisonOperator = $exp.ComparisonOperator
        $isRegex = $exp.IsRegex

        if ($null -eq $value) {
            $result = $false
            $ComparisonDataList.Value.Add([ComparisonData]::new($value, $comparisonOperator, $comparisonValue, $result))
        } else {
            $result = Resolve-Expression -value $value -comparisonValue $comparisonValue -comparisonOperator $comparisonOperator -isRegex $isRegex -ComparisonDataList $ComparisonDataList
        }
    } elseif ($node.ChildNodes) {
        $result = Test-Nodes -nodes $node.ChildNodes -data $data -ComparisonDataList $ComparisonDataList
    } else {
        $result = $true
    }

    return $result
}