function Test-Comparison {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CompOp,
        
        [Parameter(Mandatory = $true)]
        [object] $RecordValue,
        
        [Parameter(Mandatory = $true)]
        [object] $Value
    )   

    $comparisonResult = $null
    $comparisonUsed = ""

    switch ($CompOp) {
        'Equal' {
            $comparisonResult = $RecordValue -eq $Value
            $comparisonUsed   = "-eq"
        }
        'Like' {
            $comparisonResult = $RecordValue -like $Value
            $comparisonUsed   = "-like"
        }
        'NotEqual' {
            $comparisonResult = $RecordValue -ne $Value
            $comparisonUsed   = "-ne"
        }
        'LessThan' {
            $comparisonResult = [double]$RecordValue -lt [double]$Value
            $comparisonUsed   = "-lt"
        }
        'LessThanOrEqual' {
            $comparisonResult = [double]$RecordValue -le [double]$Value
            $comparisonUsed   = "-le"
        }
        'GreaterThan' {
            $comparisonResult = [double]$RecordValue -gt [double]$Value
            $comparisonUsed   = "-gt"
        }
        'GreaterThanOrEqual' {
            $comparisonResult = [double]$RecordValue -ge [double]$Value
            $comparisonUsed   = "-ge"
        }
        'Match' {
            $comparisonResult = $RecordValue -match $Value
            $comparisonUsed   = "-match"
        }
        default {
            throw "Unsupported ComparisonOperator: $CompOp"
        }
    }
    
    return [PSCustomObject]@{
        comparisonResult = $comparisonResult
        comparisonUsed = $comparisonUsed
    }
}
