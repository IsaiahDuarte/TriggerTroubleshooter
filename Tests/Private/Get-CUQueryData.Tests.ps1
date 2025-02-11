BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src')

    # Stub out commands from other modules.
    function Export-CUQuery { }
    function Invoke-CUQuery { }
}

Describe "Get-CUQueryData" {

    Context "When using the export method (UseExport switch)" {

        BeforeEach {
            Mock -CommandName Export-CUQuery { } -Verifiable

            Mock -CommandName Get-Content {
                return @'
                [{"TableName":"LogicalDisks","RecordId":"9de6c862-62f6-4c2b-ae40-20cb35f327ea","Properties":[{"InnerValue":{"fMaxValue":34.3750954,"fMinValue":25.2895756,"fMaxInHistory":34.0011253,"fAvarageValue":34.0800133,"fAvarageInHistory":33.0761452,"LastValue":{"Value":33.4275856,"TimeStamp":"2025-02-09T19:33:04.2510567"},"Tag":null,"HistorySamples":[{"Value":33.4275856,"TimeStamp":"2025-02-09T19:33:04.2510567"}],"HistorySize":1,"SeverityLevelValue":1},"PropertyName":"FreeSpacePercentage"},{"InnerValue":"C:\\","PropertyName":"DiskName"}]}]
'@
            } -Verifiable

            Mock -CommandName Remove-Item { } -Verifiable

            $expectedResult = [PSCustomObject]@{
                Key = "9de6c862-62f6-4c2b-ae40-20cb35f327ea"
                FreeSpacePercentage = 34.0800133
                DiskName = "C:\"
            }
        }

        It "calls Export-CUQuery, reads JSON, and returns processed results" {
            $result = Get-CUQueryData -Table "LogicalDisks" -Fields @("FreeSpacePercentage","DiskName") -Where "SomeFilter" -UseExport

            $result | Should -BeOfType "PSCustomObject"
            $result.Count | Should -Be 1

            # Compare properties – the Key and each field should match.
            $result[0].Key | Should -Be $expectedResult.Key
            $result[0].FreeSpacePercentage | Should -Be $expectedResult.FreeSpacePercentage
            $result[0].DiskName | Should -Be $expectedResult.DiskName
        }
    }

    Context "When using the Take parameter set (invoke-cuquery method)" {

        BeforeEach {
            $dummyInvokeResult = [PSCustomObject]@{
                Data = @(
                    [PSCustomObject]@{
                        Key = "9de6c862-62f6-4c2b-ae40-20cb35f327ea"
                        FreeSpacePercentage = 33.43
                        DiskName = "C:\"
                    }
                )
        }

            Mock -CommandName Invoke-CUQuery { return $dummyInvokeResult } -Verifiable
        }

        It "calls Invoke-CUQuery with the correct parameters and returns .Data" {
            $result = Get-CUQueryData -Table "LogicalDisks" -Fields @("FreeSpacePercentage","DiskName") -Where "SomeFilter" -Take 50

            $result | Should -BeExactly $dummyInvokeResult.Data

            Assert-MockCalled Invoke-CUQuery -Exactly 1 -Scope It
        }
    }
}