BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src').Replace('\unit','')

    # Stub out commands from other modules.
    function Export-CUQuery { }
    function Invoke-CUQuery { }

    function Write-TTLog { }
}

Describe "Get-CUQueryData" {

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