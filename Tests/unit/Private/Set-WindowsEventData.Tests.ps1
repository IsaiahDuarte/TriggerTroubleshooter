BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src').Replace('\unit','')

    function Write-TriggerTroubleshooterLog { }
}
    
Describe "Set-WindowsEventData" {
    
    Context "When an object has EntryType equal to 1" {
        It "converts EntryType 1 to 'Error'" {
            $inputData = @([PSCustomObject]@{ EntryType = 1 })
    
            $output = Set-WindowsEventData -Data $inputData
    
            $output[0].EntryType | Should -Be "Error"
        }
    }
    
    Context "When an object has an invalid EntryType (e.g. 3)" {
        It "throws an error indicating an invalid EntryType" {
            $inputData = @([PSCustomObject]@{ EntryType = 3 })
    
            { Set-WindowsEventData -Data $inputData } | Should -Throw "Error in Set-WindowsEventData: Invalid EntryType"
        }
    }
}