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
    
    [void] SetScheduleResult([bool] $result) {
        $this.ScheduleResult = $result
    }

    # Default parameter values seem to not work right in powershell.
    [void] DisplayResult () {
        $this.DisplayResult(0, [string]::Empty)
    }

    [void] DisplayResult([int] $IndentLevel = 0, [string] $PrefixOperator = '') {
        if ($IndentLevel -eq 0) {
            $separator = '─' * 60
            Write-Host "`n$separator" -ForegroundColor White
            Write-Host ("Key: {0}" -f $this.ChildNodes[0].Details.Key) -ForegroundColor White
            Write-Host ("In Schedule: {0}" -f $this.ScheduleResult) -ForegroundColor White
            Write-Host ("Are Properties Observed: {0}" -f $this.ArePropertiesObserved) -ForegroundColor White
            Write-Host ("Will Fire: {0}" -f $this.EvaluationResult) -ForegroundColor White
            Write-Host "$separator" -ForegroundColor White
        }
    
        $indent = ('    ' * $IndentLevel)
        $color = if ($this.EvaluationResult) { 'Green' } else { 'Yellow' }
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
                $detailString = "(Value: $($this.Details.RecordValue), Operator: $($this.Details.ComparisonUsed)) "
            }
    
            Write-Host ("{0}{1}- Condition: IsRegex ({2}) {3} {4}{5}" -f $indent, $prefix, $expr.IsRegex, $conditionStr, $detailString, $resultSymbol) -ForegroundColor $color
        }
    
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
}