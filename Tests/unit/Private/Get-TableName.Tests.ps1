BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src').Replace('\unit','')

    function Write-TTLog { }
}
Describe "Get-TableName" {
    Context "When TriggerType does not have a specific mapping" {
        It "returns the provided table name if available" {
            Get-TableName -TriggerType "Unknown" -TableName "CustomTable" | Should -Be "CustomTable"
        }
        It "returns the default message if no table name provided" {
            Get-TableName -TriggerType "Unknown" | Should -Be "Not returned by observable details"
        }
    }
}