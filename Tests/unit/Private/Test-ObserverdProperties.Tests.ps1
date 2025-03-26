BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1').Replace('tests', 'src').Replace('\unit', '')

    function Invoke-CUQuery { }

    function Write-TTLog { }
}
    
Describe "Test-ObserverdProperties" {
    
    Context "When Invoke-CUQuery returns no data (Total equals 0)" {
        BeforeEach {
            Mock -CommandName Invoke-CUQuery -MockWith {
                return @{
                    Total = 0
                }
            }
        }
        It "returns $false and writes a warning" {
            $result = Test-ObserverdProperties -ResourceName "TestResource" -Properties @("Prop1", "Prop2")
            $result | Should -BeFalse
        }
    }
    
    Context "When all specified properties are present" {
        BeforeEach {
            Mock -CommandName Invoke-CUQuery -MockWith {
                return @{
                    Total = 1
                    Data  = @{
                        ObserverdProps = '["Prop1", "Prop2", "Prop3"]'
                    }
                }
            }
        }
        It "returns $true" {
            $result = Test-ObserverdProperties -ResourceName "TestResource" -Properties @("Prop1", "Prop2")
            $result | Should -BeTrue
        }
    }
    
    Context "When one or more specified properties are missing" {
        BeforeEach {
            Mock -CommandName Invoke-CUQuery -MockWith {
                return @{
                    Total = 1
                    Data  = @{
                        ObserverdProps = '["Prop1", "Prop3"]'
                    }
                }
            }
        }
        It "returns $false" {
            $result = Test-ObserverdProperties -ResourceName "TestResource" -Properties @("Prop1", "Prop2")
            $result | Should -BeFalse
        }
    }
    
    Context "When ConvertFrom-Json fails due to invalid JSON" {
        BeforeEach {
            Mock -CommandName Invoke-CUQuery -MockWith {
                return @{
                    Total = 1
                    Data  = @{
                        ObserverdProps = 'Invalid JSON'
                    }
                }
            }
        }
        It "throws an error" {
            { Test-ObserverdProperties -ResourceName "TestResource" -Properties @("Prop1") } | Should -Throw
        }
    }
}