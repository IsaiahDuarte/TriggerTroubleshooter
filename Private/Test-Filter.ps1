<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER name

    .EXAMPLE

    .NOTES
#>
function Test-Filter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$filterNodes,

        [Parameter(Mandatory=$true)]
        [object]$data,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )
    $finalResult = Test-Nodes -nodes $filterNodes -data $data -ComparisonDataList $ComparisonDataList
    return $finalResult
}