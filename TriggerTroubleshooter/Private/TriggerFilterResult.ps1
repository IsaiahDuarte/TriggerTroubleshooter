class TriggerFilterResult {
    [System.Collections.Generic.List[TriggerFilterResult]] $ChildNodes
    [TriggerDataResult] $Details
    [string] $LogicalOperator
    [object] $ExpressionDescriptor
    [object] $TriggerDetails
    [bool] $EvaluationResult
    [bool] $IsNegation

    TriggerFilterResult () {
        $this.ChildNodes = [System.Collections.Generic.List[TriggerFilterResult]]::new()
    }
    
    # Default parameter values seem to not work right in powershell.
    [void] DisplayResult () {
        $this.DisplayResult(0, [string]::Empty)
    }

    [void] DisplayResult([int] $IndentLevel, [string] $PrefixOperator) {
        $indent = (' ' * 4) * $IndentLevel

        if ($this.EvaluationResult -eq $true) {
            $color = 'Green'
            $resultSymbol = '[TRUE ]'
        } else {
            $color = 'Yellow'
            $resultSymbol = '[FALSE]'
        }

        if ($this.IsNegation) {
            $notStr = 'Not '
        } else {
            $notStr = ''
        }

        if ($PrefixOperator -ne '') {
            $prefix = "$PrefixOperator "
        } else {
            $prefix = ''
        }

        if ($null -ne $this.ExpressionDescriptor) {
            $expr    = $this.ExpressionDescriptor
            $column  = $expr.Column
            $value   = $expr.Value
            $compOp  = $expr.ComparisonOperator.ToString()
            $conditionStr = "$notStr`'$column`' $compOp `'$value`'"

            $detailString = ''
            if ($null -ne $this.Details) {
                $detailString = "(Value: $($this.Details.RecordValue), Operator: $($this.Details.ComparisonUsed))"
            }

            Write-Host "$indent$prefix- Condition: $conditionStr $detailString $resultSymbol" -ForegroundColor $color
        }

        if ($null -ne $this.ChildNodes -and $this.ChildNodes.Count -gt 0) {
            if ($null -eq $this.ExpressionDescriptor) {
                Write-Host "$indent$prefix($($this.LogicalOperator)) $resultSymbol" -ForegroundColor $color
            }

            for ($i = 0; $i -lt $this.ChildNodes.Count; $i++) {
                $child = $this.ChildNodes[$i]
                $childOperator = ''

                if ($i -gt 0) {
                    $childOperator = $child.LogicalOperator
                }

                $child.DisplayResult($IndentLevel + 1, $childOperator)
            }
        }
    }
}