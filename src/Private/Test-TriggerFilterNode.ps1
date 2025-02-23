function Test-TriggerFilterNode {
    <#
        .SYNOPSIS
            Recursively evaluates a trigger filter node against a provided record. 
            
        .DESCRIPTION
            This function processes a trigger filter node by evaluating its expression descriptor
            using the Test-Comparison function. It then recursively processes any child nodes and
            accumulates the evaluation result based on their LogicalOperator properties.

        .PARAMETER Node
            A mandatory trigger filter node of type ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode.

        .PARAMETER Record
            A mandatory object that contains the data record. The record is expected to have properties
            that correspond to the column names specified in the node's expression descriptor.

        .EXAMPLE
            $result = Test-TriggerFilterNode -Node $triggerNode -Record $dataRecord
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode] $Node,

        [Parameter(Mandatory = $false)]
        [object] $Record
    )

    try {

        # Write warnings for any null record properties
        $nullProps = $Record.PSObject.Properties | Where-Object { $null -eq $_.Value }
        if ($nullProps) {
            $nullProps | ForEach-Object { Write-Warning "Null property: $($_.Name)" }
        }

        Write-Verbose "Evaluating node..."

        # Initialize the result
        $result = [TriggerFilterResult]::New()
        $result.ExpressionDescriptor = $Node.ExpressionDescriptor
        $result.IsNegation = $Node.IsNegation
        $result.LogicalOperator = $Node.LogicalOperator.ToString()

        # Evaluate the expression descriptor, if present
        $exprResult = $null
        if ($Node.ExpressionDescriptor) {
            $expr = $Node.ExpressionDescriptor
            $column = $expr.Column
            $value = $expr.Value
            $compOp = $expr.ComparisonOperator.ToString()
            $isRegex = $expr.IsRegex

            # Retrieve the corresponding property value from the record
            $recordValue = $Record.$column

            $tcParams = @{
                CompOp      = $compOp
                RecordValue = $recordValue
                Value       = $value
                IsNegation  = $Node.IsNegation
                IsRegex     = $isRegex
            }



            Write-Verbose "Evaluating ExpressionDescriptor: Column[$column], Value[$value], ComparisonOperator[$compOp], IsRegex[$isRegex]"

            if ($column -eq 'TimeWritten') {
                $tcParams.IsDateTime = $true
            }

            $comparison = Test-Comparison @tcParams
            $exprResult = $comparison.comparisonResult

            $result.Details = [TriggerDataResult]::New(
                $recordValue,
                $comparison.comparisonUsed,
                $comparison.comparisonResult,
                $Record.Key
            )
        }

        # Start with the evaluated expression result; it may be $null if no expression was defined
        $accumulatedResult = $exprResult

        # Process any child nodes
        if ($Node.ChildNodes -and $Node.ChildNodes.Count -gt 0) {
            Write-Verbose "Processing child nodes..."
            foreach ($child in $Node.ChildNodes) {
                if (-not $child) { continue }
                $childResult = Test-TriggerFilterNode -Node $child -Record $Record
                if ($null -ne $childResult) {
                    $result.ChildNodes.Add($childResult)
                }

                # If accumulated result hasn't been set yet, use the child's result
                if ($null -eq $accumulatedResult) {
                    $accumulatedResult = $childResult.EvaluationResult
                }
                else {
                    # Determine and apply the logical operator from the child node
                    $operator = $child.LogicalOperator
                    if ([string]::IsNullOrEmpty($operator)) {
                        throw "Child node is missing a LogicalOperator."
                    }

                    switch ($operator) {
                        'And' {
                            $accumulatedResult = $accumulatedResult -and $childResult.EvaluationResult
                        }
                        'Or' {
                            $accumulatedResult = $accumulatedResult -or $childResult.EvaluationResult
                        }
                        default {
                            throw "Unknown LogicalOperator: $operator"
                        }
                    }
                }
            }
        }

        # Finalize and return the result
        $result.EvaluationResult = $accumulatedResult
        Write-Verbose "Node evaluation result: $($result.EvaluationResult)"
        return $result
    }
    catch {
        Write-Error "Error in Test-TriggerFilterNode: $($_.Exception.Message)"
    }
}