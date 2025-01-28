class ExpressionNode {
    [string]$NodeType   
    [string]$Operator
    [object]$Left
    [object]$Right
    [object]$Value
    [object]$ComparisonValue 
    [bool]$Resul

    # Constructor for comparison nodes
    ExpressionNode([string]$operator, [object]$value, [object]$comparisonValue, [bool]$result){
        $this.NodeType = 'Comparison'
        $this.Operator = $operator
        $this.Value = $value
        $this.ComparisonValue = $comparisonValue
        $this.Result = $result
    }

    # Constructor for logical nodes
    ExpressionNode([string]$operator, [ExpressionNode]$left, [ExpressionNode]$right, [bool]$result){
        $this.NodeType = 'Logical'
        $this.Operator = $operator  # 'And' or 'Or'
        $this.Left = $left
        $this.Right = $right
        $this.Result = $result
    }
}