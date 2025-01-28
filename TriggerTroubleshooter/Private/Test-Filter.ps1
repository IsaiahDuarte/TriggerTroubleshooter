<#
    .SYNOPSIS
    Processes a collection of filter nodes against a data object and evaluates if they match.

    .DESCRIPTION
    The Test-Filter function acts as an interface to process filter nodes using Test-Nodes, determining if the data matches defined filter conditions.

    .PARAMETER filterNodes
    An array of nodes representing filter criteria to be evaluated against the data.

    .PARAMETER data
    The data object checked against the filter nodes to evaluate for matches.

    .EXAMPLE

    .NOTES
    This function abstracts complex node evaluation into a simpler filter processing module for broader use in evaluating conditions against data.
#>
function Test-Filter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$filterNodes,

        [Parameter(Mandatory=$true)]
        [object]$data
    )
    $finalResult = Test-Nodes -nodes $filterNodes -data $data
    return $finalResult
}