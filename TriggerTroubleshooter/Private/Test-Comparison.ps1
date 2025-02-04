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
        [bool] $IsNegation,

        [Parameter(Mandatory=$true)]
        [bool] $IsRegex
    )   

    $comparisonResult = $null
    $comparisonUsed = ""
    
    if ($CompOp -eq 'Equal' -and $Value -like '*`**' -and !$IsRegex) {
        $CompOp = 'Like'
    }

    if($IsRegex) {
        $CompOp = 'Match'
    }

    switch ($CompOp) {
        'Equal' {
            if($IsNegation) {
                $comparisonResult = $RecordValue -ne $Value
                $comparisonUsed   = "-ne"    
            } else {
                $comparisonResult = $RecordValue -eq $Value
                $comparisonUsed   = "-eq"
            }
            break
        }
        'Like' {
            if($IsNegation) {
                $comparisonResult = $RecordValue -notlike $Value
                $comparisonUsed   = "-notlike"    
            } else {
                $comparisonResult = $RecordValue -like $Value
                $comparisonUsed   = "-like"
            }
            break
        }
        'NotEqual' {
            $comparisonResult = $RecordValue -ne $Value
            $comparisonUsed   = "-ne"
        }
        'LessThan' {
            $comparisonResult = [double]$RecordValue -lt [double]$Value
            $comparisonUsed   = "-lt"
            break
        }
        'LessThanOrEqual' {
            $comparisonResult = [double]$RecordValue -le [double]$Value
            $comparisonUsed   = "-le"
            break
        }
        'GreaterThan' {
            $comparisonResult = [double]$RecordValue -gt [double]$Value
            $comparisonUsed   = "-gt"
            break
        }
        'GreaterThanOrEqual' {
            $comparisonResult = [double]$RecordValue -ge [double]$Value
            $comparisonUsed   = "-ge"
            break
        }
        'Match' {
            $comparisonResult = $RecordValue -match $Value
            $comparisonUsed   = "-match"
            break
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
