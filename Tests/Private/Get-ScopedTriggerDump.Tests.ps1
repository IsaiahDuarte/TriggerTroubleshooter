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

    # Sample object that mimics the observable details.
    # You can create a PSCustomObject with the same properties.
    # (We assume that the type is ControlUp.PowerShell.Common.Contract.ObservableTriggerService.GetObservableTriggerResponse.)
    # Here we simply create an object with the needed properties.


    Context "When the Table parameter is empty" {
        BeforeEach {
            $fakeObsDetails = Get-FakeObservableDetails
            # Set the Table property to an empty string to simulate missing table information.
            $fakeObsDetails.Table = ""
        }

        It "writes a warning and returns nothing" {
            # Capture warning output (the function uses Write-Warning).
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
            
            # We need Invoke-CUQuery to return a list of tables INCLUDING "Sessions".
            $fakeTablesObject = [PSCustomObject]@{
                data = [PSCustomObject]@{
                    TableName = @("OtherTable1", "Sessions", "OtherTable2")
                }
            }
            Mock -CommandName Invoke-CUQuery { return $fakeTablesObject } -Verifiable

            # Set up an expected result for each folder.
            # In this non-WindowsEvent path, if the TriggerType is in the $NoTableTypes, it overrides the fields.
            # Let's choose a trigger type that is not in $NoTableTypes (e.g. "SomeOtherTrigger").
            # Save an expected result in a variable defined in the BeforeEach so it's in the same scope as the tests.
            $expectedResults = @{
                "A" = [PSCustomObject]@{ key = "A"; Value = "DataA" }
                "B" = [PSCustomObject]@{ key = "B"; Value = "DataB" }
            }
            # Store it in the script scope variable for use in the It block.
            $script:expectedResults = $expectedResults

            # Mock Get-CUQueryData.
            # We check the Where parameter to simulate different results based on folder.
            Mock -CommandName Get-CUQueryData -ParameterFilter { $Where -eq "FolderPath='FolderA'" } {
                return @([PSCustomObject]@{ key = "A"; Value = "DataA" })
            } -Verifiable

            Mock -CommandName Get-CUQueryData -ParameterFilter { $Where -eq "FolderPath='FolderB'" } {
                return @([PSCustomObject]@{ key = "B"; Value = "DataB" })
            } -Verifiable
        }

        It "calls Get-CUQueryData for each folder and returns a dump containing each item keyed by item.key" {
            $dump = Get-ScopedTriggerDump -Name "Trigger3" -TriggerObservableDetails $fakeObsDetails -TriggerType "SomeOtherTrigger" -Table $fakeObsDetails.Table -Take 50

            # The returned dump should be a hashtable with keys "A" and "B".
            $dump.Keys | Should -Contain "A"
            $dump.Keys | Should -Contain "B"

            # And the values should match the expected results.
            $dump.A | Should -BeExactly $script:expectedResults.A
            $dump.B | Should -BeExactly $script:expectedResults.B

            # Ensure Get-CUQueryData was called once for each folder.
            Assert-MockCalled Get-CUQueryData -Times 2 -Scope It
        }
    }

    Context "When TriggerType is WindowsEvent" {
        BeforeEach {
            $fakeObsDetails = Get-FakeObservableDetails
            $fakeObsDetails.Table = "Sessions"
            
            # Ensure that Invoke-CUQuery returns a list including the Sessions table.
            $fakeTablesObject = [PSCustomObject]@{
                data = [PSCustomObject]@{
                    TableName = @("Sessions", "OtherTable")
                }
            }
            Mock -CommandName Invoke-CUQuery { return $fakeTablesObject } -Verifiable

            # For this test, we simulate that Get-CUQueryData (when called) returns an array with one item.
            # Later, Set-WindowsEventData should be called to adjust that data.
            Mock -CommandName Get-CUQueryData {
                return @([PSCustomObject]@{ key = "W"; OriginalData = "Original" })
            } -Verifiable

            # Now, set up the mock for Set-WindowsEventData so that it returns modified data.
            Mock -CommandName Set-WindowsEventData -ParameterFilter { $Data } {
                # For simplicity, return the data with a new key value.
                return @([PSCustomObject]@{ key = "W_modified"; Adjusted = "Modified" })
            } -Verifiable
        }

        It "calls Set-WindowsEventData and returns the modified data in the dump" {
            $dump = Get-ScopedTriggerDump -Name "Trigger4" -TriggerObservableDetails $fakeObsDetails -TriggerType "WindowsEvent" -Table $fakeObsDetails.Table -Take 50

            # Since there are two folders, the function will call Get-CUQueryData twice and then process the data via Set-WindowsEventData.
            # In this test, we expect both calls to be passed through Set-WindowsEventData and return an object with key "W_modified".
            # The dump will have only the last value for a given key; however, for our test we are interested in the fact
            # that Set-WindowsEventData was called and its modified object was inserted.
            $dump.Keys | Should -Contain "W_modified"

            # Verify the chain of calls.
            Assert-MockCalled Get-CUQueryData -Times 2 -Scope It
            Assert-MockCalled Set-WindowsEventData -Times 2 -Scope It
        }
    }

    Context "Error handling in data retrieval" {
        BeforeEach {
            $fakeObsDetails = Get-FakeObservableDetails
            $fakeObsDetails.Table = "Sessions"
            
            # Return table list that includes Sessions.
            $fakeTablesObject = [PSCustomObject]@{
                data = [PSCustomObject]@{
                    TableName = @("Sessions")
                }
            }
            Mock -CommandName Invoke-CUQuery { return $fakeTablesObject } -Verifiable

            # Have Get-CUQueryData throw an error to simulate a failure.
            Mock -CommandName Get-CUQueryData { throw "Simulated error in Get-CUQueryData" } -Verifiable
        }

        It "writes an error and rethrows when Get-CUQueryData fails" {
            { Get-ScopedTriggerDump -Name "TriggerError" -TriggerObservableDetails $fakeObsDetails -TriggerType "UserLoggedOn" -Table $fakeObsDetails.Table -Take 10 } |
            Should -Throw -ErrorMessage "Simulated error in Get-CUQueryData"
            Assert-MockCalled Get-CUQueryData -Scope It
        }
    }
}