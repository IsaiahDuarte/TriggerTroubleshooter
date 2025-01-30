function Test-Comparison {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CompOp,
        
        [Parameter(Mandatory = $true)]
        [object] $RecordValue,
        
        [Parameter(Mandatory = $true)]
        [object] $Value,
        
        [Parameter(Mandatory = $true)]
        [bool] $IsRegex
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
            if ($IsRegex) {
                $comparisonResult = -not ($RecordValue -match $Value)
                $comparisonUsed   = "-notmatch"
            } else {
                $comparisonResult = $RecordValue -ne $Value
                $comparisonUsed   = "-ne"
            }
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
        'Contains' {
            $comparisonResult = $RecordValue -like "*$Value*"
            $comparisonUsed   = "-like"
        }
        'StartsWith' {
            $comparisonResult = $RecordValue -like "$Value*"
            $comparisonUsed   = "-like"
        }
        'EndsWith' {
            $comparisonResult = $RecordValue -like "*$Value"
            $comparisonUsed   = "-like"
        }
        default {
            throw "Unsupported ComparisonOperator: $CompOp"
        }
    }

    if ($IsRegex) {
        $comparisonResult = $RecordValue -match $Value
        $comparisonUsed   = "-match"
    }
    
    return [PSCustomObject]@{
        comparisonResult = $comparisonResult
        comparisonUsed = $comparisonUsed
    }
}
