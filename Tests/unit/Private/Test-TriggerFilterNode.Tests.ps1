BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1').Replace('tests', 'src').Replace('\unit', '')
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1').Replace('tests', 'src').Replace('\unit', '').Replace('Test-TriggerFilterNode', 'Test-Comparison')
    function Write-TTLog { }

    Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Collections.Generic;

namespace ControlUp.PowerShell.Common.Contract.Triggers
{
    public class TriggerFilterNode
    {
        public ExpressionDescriptor ExpressionDescriptor { get; set; }
        public bool IsNegation { get; set; }
        public LogicalOperator LogicalOperator { get; set; }
        public List<TriggerFilterNode> ChildNodes { get; set; }

        public TriggerFilterNode()
        {
            ChildNodes = new List<TriggerFilterNode>();
        }
    }

    public class ExpressionDescriptor
    {
        public string Column { get; set; }
        public string Value { get; set; }
        public ComparisonOperator ComparisonOperator { get; set; }
        public bool IsRegex { get; set; }
    }

    public enum LogicalOperator
    {
        And,
        Or
    }

    public enum ComparisonOperator
    {
        Equal,
        NotEqual,
        GreaterThan,
        LessThan,
        Contains,
        NotContains,
        StartsWith,
        EndsWith,
        RegexMatch
    }
}

public class TriggerFilterResult
{
    public ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor ExpressionDescriptor { get; set; }
    public bool IsNegation { get; set; }
    public string LogicalOperator { get; set; }
    public TriggerDataResult Details { get; set; }
    public List<TriggerFilterResult> ChildNodes { get; set; }
    public bool EvaluationResult { get; set; }

    public TriggerFilterResult()
    {
        ChildNodes = new List<TriggerFilterResult>();
    }

    public static TriggerFilterResult New()
    {
        return new TriggerFilterResult();
    }
}

public class TriggerDataResult
{
    public object RecordValue { get; set; }
    public string ComparisonUsed { get; set; }
    public bool ComparisonResult { get; set; }
    public string Key { get; set; }

    public TriggerDataResult(object recordValue, string comparisonUsed, bool comparisonResult, string key)
    {
        RecordValue = recordValue;
        ComparisonUsed = comparisonUsed;
        ComparisonResult = comparisonResult;
        Key = key;
    }

    public static TriggerDataResult New(object recordValue, string comparisonUsed, bool comparisonResult, string key)
    {
        return new TriggerDataResult(recordValue, comparisonUsed, comparisonResult, key);
    }
}
"@
}

Describe "Test-TriggerFilterNode" {
    Context "When evaluating a single node with an expression" {
        It "Evaluates to true when the expression matches the record" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $node.ExpressionDescriptor.Column = 'Name'
            $node.ExpressionDescriptor.Value = 'Test'
            $node.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $node.ExpressionDescriptor.IsRegex = $false
            $node.IsNegation = $false
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::And

            $record = [PSCustomObject]@{
                'Name' = 'Test'
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeTrue
        }

        It "Evaluates to false when the expression does not match the record" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $node.ExpressionDescriptor.Column = 'Name'
            $node.ExpressionDescriptor.Value = 'Test'
            $node.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $node.ExpressionDescriptor.IsRegex = $false
            $node.IsNegation = $false
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::And

            $record = [PSCustomObject]@{
                'Name' = 'DifferentName'
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeFalse
        }
    }

    Context "When evaluating a node with negation" {
        It "Evaluates to false when the expression matches and negation is true" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $node.ExpressionDescriptor.Column = 'Name'
            $node.ExpressionDescriptor.Value = 'Test'
            $node.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $node.ExpressionDescriptor.IsRegex = $false
            $node.IsNegation = $true
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::And

            $record = [PSCustomObject]@{
                'Name' = 'Test'
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeFalse
        }
    }

    Context "When evaluating a node with child nodes using 'And' operator" {
        It "Evaluates to true when all child nodes evaluate to true" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::And

            # Create child node 1
            $childNode1 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode1.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode1.ExpressionDescriptor.Column = 'Name'
            $childNode1.ExpressionDescriptor.Value = 'Test'
            $childNode1.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode1.ExpressionDescriptor.IsRegex = $false
            $childNode1.IsNegation = $false
            $childNode1.LogicalOperator = 'And'

            # Create child node 2
            $childNode2 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode2.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode2.ExpressionDescriptor.Column = 'Age'
            $childNode2.ExpressionDescriptor.Value = '30'
            $childNode2.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode2.ExpressionDescriptor.IsRegex = $false
            $childNode2.IsNegation = $false
            $childNode2.LogicalOperator = 'And'

            $node.ChildNodes.Add($childNode1)
            $node.ChildNodes.Add($childNode2)

            $record = [PSCustomObject]@{
                'Name' = 'Test'
                'Age'  = 30
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeTrue
        }

        It "Evaluates to false when any child node evaluates to false" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::And

            # Create child node 1
            $childNode1 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode1.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode1.ExpressionDescriptor.Column = 'Name'
            $childNode1.ExpressionDescriptor.Value = 'Test'
            $childNode1.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode1.ExpressionDescriptor.IsRegex = $false
            $childNode1.IsNegation = $false
            $childNode1.LogicalOperator = 'And'

            # Create child node 2
            $childNode2 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode2.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode2.ExpressionDescriptor.Column = 'Age'
            $childNode2.ExpressionDescriptor.Value = '25' # Does not match
            $childNode2.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode2.ExpressionDescriptor.IsRegex = $false
            $childNode2.IsNegation = $false
            $childNode2.LogicalOperator = 'And'

            $node.ChildNodes.Add($childNode1)
            $node.ChildNodes.Add($childNode2)

            $record = [PSCustomObject]@{
                'Name' = 'Test'
                'Age'  = 30
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeFalse
        }
    }

    Context "When evaluating a node with child nodes using 'Or' operator" {
        It "Evaluates to true when at least one child node evaluates to true" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::Or

            # Create child node 1
            $childNode1 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode1.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode1.ExpressionDescriptor.Column = 'Name'
            $childNode1.ExpressionDescriptor.Value = 'Test'
            $childNode1.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode1.ExpressionDescriptor.IsRegex = $false
            $childNode1.IsNegation = $false
            $childNode1.LogicalOperator = 'Or'

            # Create child node 2
            $childNode2 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode2.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode2.ExpressionDescriptor.Column = 'Age'
            $childNode2.ExpressionDescriptor.Value = '25' # Does not match
            $childNode2.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode2.ExpressionDescriptor.IsRegex = $false
            $childNode2.IsNegation = $false
            $childNode2.LogicalOperator = 'Or'

            $node.ChildNodes.Add($childNode1)
            $node.ChildNodes.Add($childNode2)

            $record = [PSCustomObject]@{
                'Name' = 'Test'
                'Age'  = 30
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeTrue
        }

        It "Evaluates to false when all child nodes evaluate to false" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $node.LogicalOperator = [ControlUp.PowerShell.Common.Contract.Triggers.LogicalOperator]::Or

            # Create child node 1
            $childNode1 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode1.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode1.ExpressionDescriptor.Column = 'Name'
            $childNode1.ExpressionDescriptor.Value = 'WrongName'
            $childNode1.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode1.ExpressionDescriptor.IsRegex = $false
            $childNode1.IsNegation = $false
            $childNode1.LogicalOperator = 'Or'

            # Create child node 2
            $childNode2 = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $childNode2.ExpressionDescriptor = [ControlUp.PowerShell.Common.Contract.Triggers.ExpressionDescriptor]::new()
            $childNode2.ExpressionDescriptor.Column = 'Age'
            $childNode2.ExpressionDescriptor.Value = '25'
            $childNode2.ExpressionDescriptor.ComparisonOperator = [ControlUp.PowerShell.Common.Contract.Triggers.ComparisonOperator]::Equal
            $childNode2.ExpressionDescriptor.IsRegex = $false
            $childNode2.IsNegation = $false
            $childNode2.LogicalOperator = 'Or'

            $node.ChildNodes.Add($childNode1)
            $node.ChildNodes.Add($childNode2)

            $record = [PSCustomObject]@{
                'Name' = 'Test'
                'Age'  = 30
                'Key'  = '1'
            }

            $result = Test-TriggerFilterNode -Node $node -Record $record

            $result.EvaluationResult | Should -BeFalse
        }
    }

    Context "When the record has null properties" {
        It "Writes a warning for each null property" {
            $node = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::new()
            $record = [PSCustomObject]@{
                'Name' = $null
                'Age'  = $null
                'Key'  = '1'
            }

            $VerbosePreference = 'SilentlyContinue'
            Test-TriggerFilterNode -Node $node -Record $record -WarningVariable warnings 
            

            $warnings.Count | Should -Be 2
            $warnings[0].Message | Should -Match 'Null property: Name'
            $warnings[1].Message | Should -Match 'Null property: Age'
        }
    }

}