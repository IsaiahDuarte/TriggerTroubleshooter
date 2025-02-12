BeforeAll {
    # Trigger Troubleshooter module
    $modulePath = $PSCommandPath.Replace('.ps1', '.psm1').Replace('tests', 'src').Replace('\integration', '').Replace('Test-Trigger', 'TriggerTroubleshooter').Replace('\Public', '')
    Import-Module $modulePath -Force

    # Latest version of the ControlUp.PowerShell.User.dll
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramW6432")
    $userModulePath = Join-Path -Path $programFiles -ChildPath "\Smart-X\ControlUpMonitor\*\ControlUp.PowerShell.User.dll"
    $latestUserModulePath = (Get-ChildItem $userModulePath -Recurse | Sort-Object LastWriteTime -Descending)[0]
    Import-Module $latestUserModulePath
}
Describe 'Test-Trigger Integration Tests' {

    $script:testTriggerName = 'TestTriggerIntegration'

    BeforeAll {
        $existingTrigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $testTriggerName }
        if (-not $existingTrigger) {
            $splat = @{
                TriggerName             = "TestTriggerIntegration"
                TriggerType             = "Advanced"
                AdvancedTriggerSettings = @{TriggerStressRecordType = 'LogicalDisk' }
                IncidentScheduleId      = "Weekdays"
                FilterNodes             = @{
                    LogicalOperator      = 'And'
                    IsNegation           = $false
                    ExpressionDescriptor = @{
                        Column             = 'DiskName'
                        Value              = 'C:\'
                        ComparisonOperator = 'Equal'
                    }
                }
            }
            Add-CUTrigger @splat

            # Seems to be a delay :)
            Start-SLeep -Seconds 15
        }
    }

    AfterAll {
        Remove-CUTrigger -TriggerId (Get-CUTriggers | Where-Object { $_.TriggerName -eq $testTriggerName }).TriggerID
    }

    Context 'When using a valid trigger name' {

        It 'Should return results without errors' {
            $result = Test-Trigger -Name $testTriggerName -Records 5 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty

            $result.GetType().FullName | Should -Be "TriggerFilterResult[]"
        }

        It 'Should display results when -Display is specified' {
            { Test-Trigger -Name $testTriggerName -Display -Records 5 -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should work with -UseExport' {
            $result = Test-Trigger -Name $testTriggerName -UseExport

            $result | Should -Not -BeNullOrEmpty
            $result.GetType().FullName | Should -Be "TriggerFilterResult[]"

        }
    }

    Context 'When using an invalid trigger name' {

        It 'Should display a warning and return nothing' {
            Test-Trigger -Name 'InvalidTriggerName' -ErrorAction Stop -WarningVariable warnings
            $warnings | Should -Be "Trigger with name 'InvalidTriggerName' not found."
        }
    }

    Context 'When testing schedule and observed properties' {

        It 'Should have ScheduleResult and ArePropertiesObserved set correctly' {
            $result = Test-Trigger -Name $testTriggerName -Records 5 -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty

            foreach ($res in $result) {
                $res.ScheduleResult | Should -BeOfType 'System.Boolean'
                $res.ArePropertiesObserved | Should -BeOfType 'System.Boolean'
            }
        }
    }
}