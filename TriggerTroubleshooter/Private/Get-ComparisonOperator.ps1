function Get-ComparisonOperator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CompOp,

        [Parameter(Mandatory = $true)]
        [string] $Value,

        [Parameter(Mandatory=$false)]
        [bool] $IsRegex = $false
    )

    if ($CompOp -eq 'Equal' -and $Value -like '*`**' -and !$IsRegex) {
        $CompOp = 'Like'
    }

    if($IsRegex) {
        $CompOp = 'Match'
    }

    Write-Verbose "ComparisonOperator resolved to: $CompOp"

    return $CompOp
}