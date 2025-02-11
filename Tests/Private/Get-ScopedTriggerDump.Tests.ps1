BeforeAll {
    # Dot-source the function under test.
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1').Replace('tests', 'src')

    # Stub out commands from other modules.
    function Export-CUQuery { }
    function Invoke-CUQuery { }
    function Get-CUQueryData { }
    function Set-WindowsEventData { }

    Add-Type -TypeDefinition @"
namespace ControlUp.PowerShell.Common.Contract.ObservableTriggerService {
    public class GetObservableTriggerResponse {
        public string[] Filters { get; set; }
        public string[] Folders { get; set; }
        public string Table { get; set; }
    }
}
"@

    function Get-FakeObservableDetails {
        $dummy = New-Object ControlUp.PowerShell.Common.Contract.ObservableTriggerService.GetObservableTriggerResponse
        $dummy.Filters = @("FreeSpacePercentage", "DiskName")
        $dummy.Folders = @("FolderA", "FolderB")
        $dummy.Table = "Sessions"
        return $dummy
    }
}

Describe "Get-ScopedTriggerDump" {
    Context "When the Table parameter is empty" {
        BeforeEach {
            $fakeObsDetails = Get-FakeObservableDetails
            $fakeObsDetails.Table = ""
        }

        It "writes a warning and returns nothing" {
            Get-ScopedTriggerDump -Name "Trigger1" -TriggerObservableDetails $fakeObsDetails -TriggerType "UserLoggedOff" -Take 1 -WarningVariable warnings -Table ""
            $warnings | Should -Be "Observable Details didn't return a table for Trigger1"
        }
    }

    Context "When the specified table is not found" {
        BeforeEach {
            $fakeObsDetails = Get-FakeObservableDetails
        
            Mock -CommandName Invoke-CUQuery { 
                return [PSCustomObject]@{
                    data = [PSCustomObject]@{
                        TableName = @("OtherTable1", "OtherTable2")
                    }
                }  
            } -Verifiable
        }

        It "throws an error indicating the table was not found" {
            { Get-ScopedTriggerDump -Name "Trigger2" -TriggerObservableDetails $fakeObsDetails -TriggerType "UserLoggedOff" -Table $fakeObsDetails.Table -WarningVariable warnings
                $warnings | Should -Match "Table was not found: Sessions"

                Assert-MockCalled Invoke-CUQuery -Exactly 1 -Scope It
            }
        }

        Context "When a valid table is provided (non-WindowsEvent trigger)" {
            BeforeEach {
                $fakeObsDetails = Get-FakeObservableDetails
                $fakeObsDetails.Table = "Sessions"
            
                $fakeTablesObject = [PSCustomObject]@{
                    data = [PSCustomObject]@{
                        TableName = @("OtherTable1", "Sessions", "OtherTable2")
                    }
                }

                Mock -CommandName Invoke-CUQuery { return $fakeTablesObject } -Verifiable

                $expectedResults = @{
                    "A" = [PSCustomObject]@{ key = "A"; Value = "DataA" }
                }

                Mock -CommandName Get-CUQueryData {
                    return @([PSCustomObject]@{ key = "A"; Value = "DataA" })
                } -Verifiable
            }


            It "calls Get-CUQueryData for each folder and returns a dump containing each item keyed by item.key" {
                $dump = Get-ScopedTriggerDump -Name "Trigger3" -TriggerObservableDetails $fakeObsDetails -TriggerType "SomeOtherTrigger" -Table $fakeObsDetails.Table -Take 50
                $dump.Keys | Should -Contain "A"
            }
        }

        Context "When TriggerType is WindowsEvent" {
            BeforeEach {
                $fakeObsDetails = Get-FakeObservableDetails
                $fakeObsDetails.Table = "Sessions"
            
                $fakeTablesObject = [PSCustomObject]@{
                    data = [PSCustomObject]@{
                        TableName = @("Sessions", "OtherTable")
                    }
                }
                Mock -CommandName Invoke-CUQuery { return $fakeTablesObject } -Verifiable

                Mock -CommandName Get-CUQueryData {
                    return @([PSCustomObject]@{ key = "W"; OriginalData = "Original" })
                } -Verifiable

                Mock -CommandName Set-WindowsEventData {
                    return @([PSCustomObject]@{ key = "W_modified"; Adjusted = "Modified" })
                } -Verifiable
            }

            It "calls Set-WindowsEventData and returns the modified data in the dump" {
                $dump = Get-ScopedTriggerDump -Name "Trigger4" -TriggerObservableDetails $fakeObsDetails -TriggerType "WindowsEvent" -Table $fakeObsDetails.Table -Take 50
                $dump.Keys | Should -Contain "W_modified"
            }
        }

        Context "Error handling in data retrieval" {
            BeforeEach {
                $fakeObsDetails = Get-FakeObservableDetails
                $fakeObsDetails.Table = "Sessions"
            
                $fakeTablesObject = [PSCustomObject]@{
                    data = [PSCustomObject]@{
                        TableName = @("Sessions")
                    }
                }
                Mock -CommandName Invoke-CUQuery { return $fakeTablesObject } -Verifiable

                Mock -CommandName Get-CUQueryData { throw "Simulated error in Get-CUQueryData" } -Verifiable
            }

            It "writes an error and rethrows when Get-CUQueryData fails" {
                { Get-ScopedTriggerDump -Name "TriggerError" -TriggerObservableDetails $fakeObsDetails -TriggerType "UserLoggedOn" -Table $fakeObsDetails.Table -Take 10 } |
                Should -Throw "Simulated error in Get-CUQueryData"
                Assert-MockCalled Get-CUQueryData -Scope It
            }
        }
    }
}