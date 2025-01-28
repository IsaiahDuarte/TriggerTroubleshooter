<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER name

    .EXAMPLE

    .NOTES
#>
class ComparisonData {
    [object] $LeftValue
    [string] $Operator
    [object] $RightValue
    [bool] $Result

    ComparisonData([object]$leftValue, [string]$operator, [object]$rightValue, [bool]$result){
        $this.LeftValue = $leftValue
        $this.Operator = $operator
        $this.RightValue = $rightValue
        $this.Result = $result
    }
}