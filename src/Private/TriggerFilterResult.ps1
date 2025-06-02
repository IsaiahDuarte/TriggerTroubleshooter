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
                return ""
            }

            if ($IndentLevel -eq 0) {
                $separator = '=' * 60
                # Append the header lines.
                $sb.AppendLine("`n$separator") | Out-Null
                if ($this.ChildNodes.Count -gt 0 -and $this.ChildNodes[0].Details) {
                    $sb.AppendLine(("Key: {0}" -f $this.ChildNodes[0].Details.Key)) | Out-Null
                }
                $sb.AppendLine(("Identity: {0}" -f $this.IdentityField)) | Out-Null
                $sb.AppendLine(("In Schedule: {0}" -f $this.ScheduleResult)) | Out-Null
                $sb.AppendLine(("Are Properties Observed: {0}" -f $this.ArePropertiesObserved)) | Out-Null
                $sb.AppendLine(("Last Inspection Time: {0}" -f $this.LastInspectionTime))
                $sb.AppendLine(("Will Fire: {0}" -f $this.EvaluationResult)) | Out-Null
                $sb.AppendLine($separator) | Out-Null
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
                $sb.AppendLine($line) | Out-Null
            }

            if ($this.ChildNodes -and $this.ChildNodes.Count -gt 0) {
                if (-not $this.ExpressionDescriptor) {
                    $line = "{0}{1}({2}) {3}" -f $indent, $prefix, $this.LogicalOperator, $resultSymbol
                    $sb.AppendLine($line) | Out-Null
                }

                for ($i = 0; $i -lt $this.ChildNodes.Count; $i++) {
                    $child = $this.ChildNodes[$i]
                    $childOperator = if ($i -gt 0) { $child.LogicalOperator } else { '' }
                    # Recursively build the child’s string output.
                    $childSb = $child.BuildResultString($IndentLevel + 1, $childOperator, $OnlyTrue)
                    $sb.Append($childSb.ToString()) | Out-Null
                }
            }
        }
        catch {
            $sb.AppendLine("Error in BuildResultString: $($_.Exception.Message)") | Out-Null
        }

        return $sb.ToString()
    }

    [void] DisplayResult() {
        Write-Host $this.BuildResultString(0, "", $false)
    }

    [void] DisplayResult([bool] $OnlyTrue) {
        Write-Host $this.BuildResultString(0, "", $OnlyTrue)
    }
} 