function Test-Comparison {
    <#
        .SYNOPSIS
            Compares a record value to a given value using a specified comparison operator. 

        .DESCRIPTION
            This function evaluates a comparison between the provided record value and value based on 
            the operator specified by the CompOp parameter. Other options such as negation and regex.
            This was made for data from a TriggerFilterNode

        .PARAMETER CompOp
            The comparison operator to use. Supported values include: Equal, Like, LessThan, 
            LessThanOrEqual, GreaterThan, GreaterThanOrEqual, and Match.

        .PARAMETER RecordValue
            The value from the record that will be compared.

        .PARAMETER Value
            The value to compare against the RecordValue.

        .PARAMETER IsNegation
            A switch indicating whether to negate the result of the comparison.

        .PARAMETER IsRegex
            A switch indicating whether the comparison should be performed based on regular expression matching.

        .EXAMPLE
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc' -Value 'abc' -IsNegation $false -IsRegex $false
    #>
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

        [Parameter(Mandatory = $true)]
        [bool] $IsRegex
    )

    try {
        $comparisonResult = $null
        $comparisonUsed = ""

        # Adjust the operator: if CompOp is Equal and the value contains wildcards (unless using regex),
        # use the Like operator.
        if ($CompOp -eq 'Equal' -and $Value -like '*`**' -and -not $IsRegex) {
            $CompOp = 'Like'
        }

        # If regex matching is requested, force the operator to Match.
        if ($IsRegex) {
            $CompOp = 'Regex'
        }

        switch ($CompOp) {
            'Equal' {
                if ($IsNegation) {
                    $comparisonResult = $RecordValue -ne $Value
                    $comparisonUsed = "-ne"    
                }
                else {
                    $comparisonResult = $RecordValue -eq $Value
                    $comparisonUsed = "-eq"
                }
                break
            }
            
            # Need to verify how this is actually processed by the monitor
            'Like' {
                if ($IsNegation) {
                    $comparisonResult = $RecordValue -notlike $Value
                    $comparisonUsed = "-notlike"    
                }
                else {
                    $comparisonResult = $RecordValue -like $Value
                    $comparisonUsed = "-like"
                }
                break
            }

            'LessThan' {
                $comparisonResult = [double]$RecordValue -lt [double]$Value
                $comparisonUsed = "-lt"
                break
            }

            'LessThanOrEqual' {
                $comparisonResult = [double]$RecordValue -le [double]$Value
                $comparisonUsed = "-le"
                break
            }

            'GreaterThan' {
                $comparisonResult = [double]$RecordValue -gt [double]$Value
                $comparisonUsed = "-gt"
                break
            }

            'GreaterThanOrEqual' {
                $comparisonResult = [double]$RecordValue -ge [double]$Value
                $comparisonUsed = "-ge"
                break
            }

            'Regex' {
                $comparisonResult = ([Regex]::Match($RecordValue, $Value)).Success
                $comparisonUsed = "[Regex]::Match"
                break
            }
            default {
                throw "Unsupported ComparisonOperator: $CompOp"
            }
        }

        return [PSCustomObject]@{
            comparisonResult = $comparisonResult
            comparisonUsed   = $comparisonUsed
        }
    }
    catch {
        Write-Error "Error in Test-Comparison: $($_.Exception.Message)"
        throw
    }
} 