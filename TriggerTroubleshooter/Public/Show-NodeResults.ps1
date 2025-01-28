function Show-NodeResults {
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Node,

        [string]$Indent = "",
        [bool]$IsTopNode = $true
    )

    $childIndent = $Indent + "  "

    switch ($Node.NodeType) {
        'Comparison' {
            $resultColor = if ($Node.Result) { 'Green' } else { 'Red' }
            Write-Host "$Indent$($Node.Value) $($Node.Operator) $($Node.ComparisonValue) => $($Node.Result)" -ForegroundColor $resultColor
        }
        'Logical' {
            if (-not $IsTopNode) {
                $resultColor = if ($Node.Result) { 'Green' } else { 'Red' }
                Write-Host "$Indent$($Node.Operator) => $($Node.Result)" -ForegroundColor $resultColor
            }
            if ($Node.Left) {
                Show-NodeResults -Node $Node.Left -Indent $childIndent -IsTopNode:$false
            }
            if ($Node.Right) {
                Show-NodeResults -Node $Node.Right -Indent $childIndent -IsTopNode:$false
            }
        }
        'Not' {
            Write-Host "$Indent NOT"
            if ($Node.Left) {
                Show-NodeResults -Node $Node.Left -Indent $childIndent -IsTopNode:$false
            }
        }
        default {
            Write-Host "$Indent Unknown NodeType: $($Node.NodeType)"
        }
    }
}