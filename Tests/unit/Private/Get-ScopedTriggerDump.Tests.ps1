BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src').Replace('\unit','')

    # Stub out commands from other modules.
    function Export-CUQuery { }
    function Invoke-CUQuery { }
    function Get-CUQueryData { }
    function Set-WindowsEventData { }

    function Get-IdentityPropertyFromTable { }

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