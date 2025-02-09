BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src')
}
Describe "Get-TableName" {
    Context "When TriggerType has a specific mapping" {
        It "returns SessionsView for UserLoggedOff" {
            Get-TableName -TriggerType "UserLoggedOff" | Should -Be "SessionsView"
        }
        It "returns SessionsView for UserLoggedOn" {
            Get-TableName -TriggerType "UserLoggedOn" | Should -Be "SessionsView"
        }
        It "returns Events for WindowsEvent" {
            Get-TableName -TriggerType "WindowsEvent" | Should -Be "Events"
        }
        It "returns Processes for ProcessStarted" {
            Get-TableName -TriggerType "ProcessStarted" | Should -Be "Processes"
        }
        It "returns Processes for ProcessEnded" {
            Get-TableName -TriggerType "ProcessEnded" | Should -Be "Processes"
        }
        It "returns ComputerView for MachineDown" {
            Get-TableName -TriggerType "MachineDown" | Should -Be "ComputerView"
        }
        It "returns SessionsView for SessionStateChanged" {
            Get-TableName -TriggerType "SessionStateChanged" | Should -Be "SessionsView"
        }
    }

    Context "When TriggerType does not have a specific mapping" {
        It "returns the provided table name if available" {
            Get-TableName -TriggerType "Unknown" -TableName "CustomTable" | Should -Be "CustomTable"
        }
        It "returns the default message if no table name provided" {
            Get-TableName -TriggerType "Unknown" | Should -Be "Not returned by observable details"
        }
    }

    Context "When TriggerType is StressLevel" {
        BeforeEach {
            Mock Write-Warning {} -Verifiable
        }
        It "writes a warning and returns default message when no table name provided" {
            Get-TableName -TriggerType "StressLevel" | Should -Be "Not returned by observable details"
            Should -Invoke Write-Warning -Exactly 1
        }
        It "writes a warning and returns the provided table name when one is specified" {
            Get-TableName -TriggerType "StressLevel" -TableName "ProvidedTable" | Should -Be "ProvidedTable"
            Should -Invoke Write-Warning -Exactly 1
        }
    }
}