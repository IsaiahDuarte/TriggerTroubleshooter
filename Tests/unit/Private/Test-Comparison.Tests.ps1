BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src').Replace('\unit','')

    function Write-TriggerTroubleshooterLog { }
}

Describe "Test-Comparison" {

    Context "Equal comparisons" {
        It "returns true when RecordValue equals Value with IsNegation false" {
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc' -Value 'abc' -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '-eq'
        }

        It "returns false when RecordValue does not equal Value with IsNegation false" {
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc' -Value 'def' -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $false
            $result.comparisonUsed | Should -Be '-eq'
        }

        It "returns false when RecordValue equals Value with IsNegation true" {
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'same' -Value 'same' -IsNegation:$true -IsRegex:$false
            # Because the underlying comparison is "not equal"
            $result.comparisonResult | Should -Be $false
            $result.comparisonUsed | Should -Be '-ne'
        }

        It "returns true when RecordValue does not equal Value with IsNegation true" {
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc' -Value 'def' -IsNegation:$true -IsRegex:$false
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '-ne'
        }
    }

    Context "Equal with wildcard (adjusted to Like)" {
        It "converts Equal to Like when the value contains a wildcard and IsRegex is false" {
            $wildcardValue = "a*"
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc' -Value $wildcardValue -IsNegation:$false -IsRegex:$false
            # ComparisonUsed should reflect the -like operator
            $result.comparisonUsed | Should -Be '-like'
            # And the comparison result should adhere to the Like operator behavior.
            $result.comparisonResult | Should -Be $true
        }
    }

    Context "Numeric comparisons" {
        It "returns true for LessThan when RecordValue is less than Value" {
            $result = Test-Comparison -CompOp 'LessThan' -RecordValue 3 -Value 5 -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '-lt'
        }

        It "returns false for LessThan when RecordValue is not less than Value" {
            $result = Test-Comparison -CompOp 'LessThan' -RecordValue 5 -Value 3 -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $false
            $result.comparisonUsed | Should -Be '-lt'
        }

        It "returns true for LessThanOrEqual when values are equal" {
            $result = Test-Comparison -CompOp 'LessThanOrEqual' -RecordValue 5 -Value 5 -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '-le'
        }

        It "returns true for GreaterThan when RecordValue is greater than Value" {
            $result = Test-Comparison -CompOp 'GreaterThan' -RecordValue 10 -Value 5 -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '-gt'
        }

        It "returns true for GreaterThanOrEqual when RecordValue equals Value" {
            $result = Test-Comparison -CompOp 'GreaterThanOrEqual' -RecordValue 10 -Value 10 -IsNegation:$false -IsRegex:$false
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '-ge'
        }
    }

    Context "Regex comparisons" {
        It "forces Regex matching when IsRegex is true" {
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc123xyz' -Value '\d{3}' -IsNegation:$false -IsRegex:$true
            $result.comparisonResult | Should -Be $true
            $result.comparisonUsed | Should -Be '[Regex]::Match'
        }

        It "returns false for a regex that does not match" {
            $result = Test-Comparison -CompOp 'Equal' -RecordValue 'abc' -Value '\d+' -IsNegation:$false -IsRegex:$true
            $result.comparisonResult | Should -Be $false
            $result.comparisonUsed | Should -Be '[Regex]::Match'
        }
    }

    Context "Unsupported operator" {
        It "throws an error for an unsupported operator" {
            { Test-Comparison -CompOp 'NotSupported' -RecordValue 'abc' -Value 'abc' -IsNegation:$false -IsRegex:$false } | Should -Throw "Unsupported ComparisonOperator: NotSupported"
        }
    }
}