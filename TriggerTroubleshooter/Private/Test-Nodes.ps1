function Test-Nodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array] $Nodes,

        [Parameter(Mandatory = $true)]
        [object] $Data,

        [Parameter(Mandatory = $true)]
        [ref] $ComparisonDataList
    )

    $result = $null

    for ($Index = 0; $Index -lt $Nodes.Count; $Index++) {
        $result = $Nodes[$Index]

        $nodeResult = Test-Node -Node $result -Data $Data -ComparisonDataList $ComparisonDataList
        Write-Debug "Node $Index Result: $nodeResult"

        if ($result.IsNegation) {
            $nodeResult = -not $nodeResult
        }

        if ($null -eq $result) {
            $result = $nodeResult
            Write-Debug "Initial Result Set To: $result"
        } else {
            $logicalOperator = $result.LogicalOperator
            Write-Debug "Logical Operator: $logicalOperator"

            switch ($logicalOperator) {
                'And' {
                    $result = $result -and $nodeResult
                    Write-Debug "Updated Result (And): $result"
                    if (-not $result) { break }
                }
                'Or' {
                    $result = $result -or $nodeResult
                    Write-Debug "Updated Result (Or): $result"
                    if ($result) { break }
                }
                default {
                    throw "Unknown LogicalOperator: $logicalOperator"
                }
            }
        }

        if ($logicalOperator -eq 'And' -and -not $result) { break }
        if ($logicalOperator -eq 'Or' -and $result) { break }
    }

    Write-Debug "Final Result: $result"
    return $result
}