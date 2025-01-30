function Get-ComparisonOperator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CompOp,

        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    if ($CompOp -eq 'Equal' -and $Value -like '*`**') {
        $CompOp = 'Like'
    }

    Write-Verbose "ComparisonOperator resolved to: $CompOp"

    return $CompOp
}