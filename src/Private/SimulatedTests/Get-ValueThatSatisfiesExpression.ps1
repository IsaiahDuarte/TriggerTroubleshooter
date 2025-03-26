function Get-ValueThatSatisfiesExpression {
    <#
    .SYNOPSIS
        Generates a value that satisfies a given FilterNodeExpressionDescriptor.
    
    .DESCRIPTION
        Based on the provided expression descriptor and negation flag, this function produces a value adjusted according to
        the specified comparison operator and column requirements.
    
    .PARAMETER expr
        A FilterNodeExpressionDescriptor object containing the column, comparison operator, and value.
    
    .PARAMETER isNegation
        A Boolean flag indicating whether to negate the comparison.
    
    .EXAMPLE
        Get-ValueThatSatisfiesExpression -expr $descriptor -isNegation $false
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.FilterNodeExpressionDescriptor] $expr,
    
        [Parameter(Mandatory = $true)]
        [bool] $isNegation
    )
    
    try {
        Write-TTLog "Processing expression for column '$($expr.Column)' with operator '$($expr.ComparisonOperator)' and value '$($expr.Value)'."
            
        $column = $expr.Column
        $op = $expr.ComparisonOperator.ToString()
        $value = $expr.Value
    
        if ($column -eq 'EntryType') {
            Write-TTLog "Mapping EntryType from string to numeric code."
            $value = switch ($value) {
                "Error" { 1 }
                "Information" { 2 }
                "Warning" { 3 }
                default { 2 }
            }
        }
    
        switch ($op) {
            'Equal' {
                Write-TTLog "Operator Equal detected."
                if (-not $isNegation) {
                    return $value
                }
                else {
                    return Get-NotEqualValue -columnName $column -compareValue $value
                }
            }
            'Like' {
                Write-TTLog "Operator Like detected."
                if (-not $isNegation) {
                    if ($value -is [string]) {
                        return $value -replace '\*', 'Something'
                    }
                    return $value
                }
                else {
                    return "NotMatchingPatternXYZ"
                }
            }
            'LessThan' {
                Write-TTLog "Operator LessThan detected."
                if (-not $isNegation) {
                    return ([double]$value - 1)
                }
                else {
                    return ([double]$value + 1)
                }
            }
            'LessThanOrEqual' {
                Write-TTLog "Operator LessThanOrEqual detected."
                if (-not $isNegation) {
                    return ([double]$value)
                }
                else {
                    return ([double]$value + 1)
                }
            }
            'GreaterThan' {
                Write-TTLog "Operator GreaterThan detected."
                if (-not $isNegation) {
                    return ([double]$value + 1)
                }
                else {
                    return ([double]$value - 1)
                }
            }
            'GreaterThanOrEqual' {
                Write-TTLog "Operator GreaterThanOrEqual detected."
                if (-not $isNegation) {
                    return ([double]$value)
                }
                else {
                    return ([double]$value - 1)
                }
            }
            default {
                throw "Unsupported operator '$op'."
            }
        }
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-ValueThatSatisfiesExpression: $($_.Exception.Message)"
        throw
    }
}