BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1').Replace('tests', 'src').Replace('\unit', '')

    function Write-TTLog { }
}
    
Describe "Get-IdentityPropertyFromTable" {
    
    Context "When given a table name that does not match any cases" {
    
        It "returns an empty string for an unknown table" {
            Get-IdentityPropertyFromTable -Table "NonExistingTable" | Should -Be ""
        }
    
        It "returns an empty string when no table is provided" {
            Get-IdentityPropertyFromTable | Should -Be ""
        }
    
    }
}