<#
.SYNOPSIS
    Represents the result of filtering a trigger, including child filter results and detailed evaluation data. 

.DESCRIPTION
    The TriggerFilterResult class holds the evaluation output for a trigger's filtering criteria.
    It includes properties for child nodes, details, logical operator, and evaluation results. It also
    supports a recursive display of results with indentation. The default constructor initializes the
    child nodes list. 
#>
class TriggerFilterResult {
    [System.Collections.Generic.List[TriggerFilterResult]] $ChildNodes
    [TriggerDataResult] $Details
    [string] $LogicalOperator
    [object] $ExpressionDescriptor
    [object] $TriggerDetails
    [bool] $EvaluationResult
    [bool] $IsNegation
    [bool] $ScheduleResult
    [bool] $ArePropertiesObserved 
    TriggerFilterResult () {
        $this.ChildNodes = [System.Collections.Generic.List[TriggerFilterResult]]::new()
    }

    <#
    .SYNOPSIS
        Displays the trigger filter result with default formatting.
    .DESCRIPTION
        Calls the detailed DisplayResult method with no indentation and no prefix.
        This overload facilitates a simpler call without parameters.
    #>
    [void] DisplayResult () {
        try {
            $this.DisplayResult(0, [string]::Empty)
        }
        catch {
            Write-Error "Error in DisplayResult (parameterless): $($_.Exception.Message)"
        }
    }

    <#
    .SYNOPSIS
        Displays the trigger filter result with formatting support.
    .DESCRIPTION
        Recursively displays the trigger filter result and its child nodes with appropriate
        indentation. Uses Write-Host with color coding to display evaluation results and details.
    .PARAMETER IndentLevel
        An integer indicating the indentation level for the display.
    .PARAMETER PrefixOperator
        An optional string prefix to show any logical operator before the condition.
    #>
    [void] DisplayResult([int] $IndentLevel = 0, [string] $PrefixOperator = '') {
        try {
            if ($IndentLevel -eq 0) {
                $separator = '=' * 60
                Write-Host "`n$separator" -ForegroundColor White
                # Guard access to ChildNodes in case it is empty
                if ($this.ChildNodes.Count -gt 0 -and $this.ChildNodes[0].Details) {
                    Write-Host ("Key: {0}" -f $this.ChildNodes[0].Details.Key) -ForegroundColor White
                }
                Write-Host ("In Schedule: {0}" -f $this.ScheduleResult) -ForegroundColor White
                Write-Host ("Are Properties Observed: {0}" -f $this.ArePropertiesObserved) -ForegroundColor White
                Write-Host ("Will Fire: {0}" -f $this.EvaluationResult) -ForegroundColor White
                Write-Host "$separator" -ForegroundColor White
            }
            $indent = ('    ' * $IndentLevel)
            $color = if ($this.EvaluationResult) { 'Green' } else { 'Yellow' }
            $resultSymbol = if ($this.EvaluationResult) { '[TRUE ]' } else { '[FALSE]' }
            $prefix = if ($PrefixOperator) { "$PrefixOperator " } else { '' }

            # Display condition if ExpressionDescriptor is provided
            if ($this.ExpressionDescriptor) {
                $expr = $this.ExpressionDescriptor
                $column = $expr.Column
                $value = $expr.Value
                $compOp = $expr.ComparisonOperator.ToString()
                $conditionStr = "'$column' $compOp '$value'"
                $detailString = ''
                if ($this.Details) {
                    $detailString = "(Value: $($this.Details.RecordValue), Operator: $($this.Details.ComparisonUsed)) "
                }
                Write-Host ("{0}{1}- Condition: IsRegex ({2}) {3} {4}{5}" -f $indent, $prefix, $expr.IsRegex, $conditionStr, $detailString, $resultSymbol) -ForegroundColor $color
            }

            # Display logical operator for non-expression nodes and process child nodes recursively
            if ($this.ChildNodes -and $this.ChildNodes.Count -gt 0) {
                if (-not $this.ExpressionDescriptor) {
                    Write-Host ("{0}{1}({2}) {3}" -f $indent, $prefix, $this.LogicalOperator, $resultSymbol) -ForegroundColor $color
                }
                for ($i = 0; $i -lt $this.ChildNodes.Count; $i++) {
                    $child = $this.ChildNodes[$i]
                    $childOperator = if ($i -gt 0) { $child.LogicalOperator } else { '' }
                    $child.DisplayResult($IndentLevel + 1, $childOperator)
                }
            }
        }
        catch {
            Write-Error "Error in DisplayResult (detailed): $($_.Exception.Message)"
        }
    }

} 