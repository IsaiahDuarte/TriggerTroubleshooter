class ExpressionNode {
    [string] $Operator
    [object] $Left
    [object] $Right
    [bool] $Result

    ExpressionNode([string]$Operator, [object]$Left, [object]$Right, [bool]$Result) {
        $this.Operator = $Operator
        $this.Left = $Left
        $this.Right = $Right
        $this.Result = $Result
    }

    [string] GetExpression([int]$indent = 0) {
        $indentStr = " " * $indent
        $operatorStr = $this.Operator

        $resultStr = if ($this.Result) {
            "[True ]"
        } else {
            "[False]"
        }

        if ($this.Operator -in @('And', 'Or', 'Not')) {
            $leftExpr = $null
            $rightExpr = $null

            if ($this.Left -is [ExpressionNode]) {
                $leftExpr = $this.Left.GetExpression($indent + 4)
            } else {
                $leftExpr = "$indentStr    $($this.Left)"
            }

            if ($this.Right -is [ExpressionNode]) {
                $rightExpr = $this.Right.GetExpression($indent + 4)
            } elseif ($this.Operator -ne 'Not') {
                $rightExpr = "$indentStr    $($this.Right)"
            }

            $expr = "$indentStr$operatorStr $resultStr`n$leftExpr"
            if ($rightExpr) {
                $expr += "`n$rightExpr"
            }
            return $expr
        } else {
            $expr = "$indentStr$($this.Left) $operatorStr $($this.Right) $resultStr"
            return $expr
        }
    }

    [void] WriteExpression([int]$indent = 0) {
        $indentStr = " " * $indent
        $operatorStr = $this.Operator

        if ($this.Result) {
            $color = 'Green'
        } else {
            $color = 'Red'
        }

        if ($this.Operator -in @('And', 'Or', 'Not')) {
            Write-Host "$indentStr$operatorStr [Result: $($this.Result)]" -ForegroundColor $color

            if ($this.Left -is [ExpressionNode]) {
                $this.Left.WriteExpression($indent + 4)
            } else {
                Write-Host "$indentStr    $($this.Left)" -ForegroundColor $color
            }

            if ($this.Right -is [ExpressionNode]) {
                $this.Right.WriteExpression($indent + 4)
            } elseif ($this.Operator -ne 'Not') {
                Write-Host "$indentStr    $($this.Right)" -ForegroundColor $color
            }
        } else {
            Write-Host "$indentStr$($this.Left) $operatorStr $($this.Right) [Result: $($this.Result)]" -ForegroundColor $color
        }
    }
}