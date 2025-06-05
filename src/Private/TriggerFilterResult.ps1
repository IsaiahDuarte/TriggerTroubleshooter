<#
    .SYNOPSIS
        Represents the result of filtering a trigger, including child filter results and detailed evaluation data. 

    .DESCRIPTION
        The TriggerFilterResult class holds the evaluation output for a trigger's filtering criteria.
        It includes properties for child nodes, details, logical operator, and evaluation results. It also
        supports displaying of results.
#>

class TriggerFilterResult {
    [System.Collections.Generic.List[TriggerFilterResult]] $ChildNodes

    [TriggerDataResult] $Details
    
    [string] $LogicalOperator

    [object] $ExpressionDescriptor
    
    [bool] $EvaluationResult
    
    [bool] $IsNegation
    
    [bool] $ScheduleResult

    [string] $IdentityField
    
    [bool] $ArePropertiesObserved 

    [datetime] $LastInspectionTime
    
    TriggerFilterResult () {
        $this.ChildNodes = [System.Collections.Generic.List[TriggerFilterResult]]::new()
    }

    [string] BuildResultString([int] $IndentLevel = 0, [string] $PrefixOperator = '', [bool] $OnlyTrue = $false) {
        $sb = New-Object System.Text.StringBuilder

        try {
            if ($OnlyTrue -and (-not $this.EvaluationResult)) {
                return $null
            }

            if ($IndentLevel -eq 0) {
                $separator = '=' * 60
                # Append the header lines.
                [void] $sb.AppendLine("`n$separator")
                if ($this.ChildNodes.Count -gt 0 -and $this.ChildNodes[0].Details) {
                    [void] $sb.AppendLine(("Key: {0}" -f $this.ChildNodes[0].Details.Key))
                }
                [void] $sb.AppendLine(("Identity: {0}" -f $this.IdentityField))
                [void] $sb.AppendLine(("In Schedule: {0}" -f $this.ScheduleResult))
                [void] $sb.AppendLine(("Are Properties Observed: {0}" -f $this.ArePropertiesObserved))
                [void] $sb.AppendLine(("Last Inspection Time: {0}" -f $this.LastInspectionTime))
                [void] $sb.AppendLine(("Will Fire: {0}" -f $this.EvaluationResult))
                [void] $sb.AppendLine($separator)
            }

            $indent = ('    ' * $IndentLevel)
            $resultSymbol = if ($this.EvaluationResult) { '[TRUE ]' } else { '[FALSE]' }
            $prefix = if ($PrefixOperator) { "$PrefixOperator " } else { '' }

            if ($this.ExpressionDescriptor) {
                $expr = $this.ExpressionDescriptor
                $column = $expr.Column
                $value = $expr.Value
                $compOp = $expr.ComparisonOperator.ToString()
                $conditionStr = "'$column' $compOp '$value'"
                $detailString = ''
                if ($this.Details) {
                    $detailString = "(Value: $($this.Details.RecordValue), Operator: $($this.Details.ComparisonUsed))"
                }
                $line = "{0}{1}- Condition: IsRegex ({2}) {3} {4} {5}" -f $indent, $prefix, $expr.IsRegex, $conditionStr, $detailString, $resultSymbol
                [void] $sb.AppendLine($line)
            }

            if ($this.ChildNodes -and $this.ChildNodes.Count -gt 0) {
                if (-not $this.ExpressionDescriptor) {
                    $line = "{0}{1}({2}) {3}" -f $indent, $prefix, $this.LogicalOperator, $resultSymbol
                    [void] $sb.AppendLine($line)
                }

                for ($i = 0; $i -lt $this.ChildNodes.Count; $i++) {
                    $child = $this.ChildNodes[$i]
                    $childOperator = if ($i -gt 0) { $child.LogicalOperator } else { '' }
                    $childOutput = $child.BuildResultString($IndentLevel + 1, $childOperator, $OnlyTrue)
                    if (-not [string]::IsNullOrWhiteSpace($childOutput)) {
                        [void] $sb.Append($childOutput)
                    }
                }
            }
        }
        catch {
            [void] $sb.AppendLine("Error in BuildResultString: $($_.Exception.Message)")
        }

        return $sb.ToString()
    }

    [void] DisplayResult() {
        Write-Host $this.BuildResultString(0, "", $false)
    }

    [void] DisplayResult([bool] $OnlyTrue) {
        [string] $line = $this.BuildResultString(0, "", $OnlyTrue)
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-Host $line
        }
    }
} 