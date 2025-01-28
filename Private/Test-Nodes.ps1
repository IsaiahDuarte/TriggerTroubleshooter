<#}
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER nodes

    .PARAMETER data

    .EXAMPLE

    .NOTES
#>
function Test-Nodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array] $nodes,

        [Parameter(Mandatory=$true)]
        [object] $data,

        [Parameter(Mandatory=$true)]
        [ref]$ComparisonDataList
    )

    $result = $null
    for ($i = 0; $i -lt $nodes.Count; $i++) {
        $node = $nodes[$i]
        $nodeResult = Test-Node -node $node -data $data -ComparisonDataList $ComparisonDataList

        if ($node.IsNegation) {
            $nodeResult = -not $nodeResult
        }

        if ($null -eq $result) {
            $result = $nodeResult
        } else {
            $logicalOperator = $node.LogicalOperator
            if ($logicalOperator -eq 'And') {
                $result = $result -and $nodeResult
                if (-not $result) { break }
            } elseif ($logicalOperator -eq 'Or') {
                $result = $result -or $nodeResult
                if ($result) { break }
            } else {
                throw "Unknown LogicalOperator: $logicalOperator"
            }
        }
    }
    return $result
}