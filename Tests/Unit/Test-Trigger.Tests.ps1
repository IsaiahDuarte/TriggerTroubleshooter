# This script contains Pester tests for the Test-Trigger cmdlet.
# It loads necessary assemblies and modules, mocks dependent commands,
# and verifies behavior when triggers exist or not.

# Load the DataContract Serialization assembly (needed for file serialization)
Add-Type -AssemblyName System.Runtime.Serialization

function Get-ControlUpDll {
    # Finds the most recently accessed ControlUp.Powershell.User.dll file.
    $dllPath = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" |
        Sort-Object -Property LastAccessTime -Descending |
        Select-Object -First 1

    if (-not $dllPath) {
        throw "Unable to locate ControlUp.Powershell.User.dll."
    }
    return $dllPath.FullName
}

function Import-ControlUpUserModule {
    $dll = Get-ControlUpDll
    Import-Module $dll -ErrorAction Stop
}

# Load the ControlUp modules (the one under test and any helper modules)
Import-ControlUpUserModule

# Determine local paths using $PSScriptRoot
$triggerDetailsPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-Trigger.Tests.TriggerDetails.xml"
$triggerFilterResultsPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-Trigger.Tests.TriggerFilterResult.xml"

# Assume that the tests folder is a child of the repository root, and the module is stored under TriggerTroubleshooter
$testsPath = Split-Path -Path $PSScriptRoot -Parent
$repoRoot = Split-Path -Path $testsPath -Parent
$modulePath = Join-Path -Path $repoRoot -ChildPath "TriggerTroubleshooter\TriggerTroubleshooter.psd1"
Import-Module $modulePath -ErrorAction Stop

Describe "Test-Trigger" {

    BeforeEach {
        # Mock Get-CUTriggers
        Mock -CommandName Get-CUTriggers -MockWith {
            [PSCustomObject]@{
                TriggerName = "ValidTrigger"
                TriggerId   = [Guid]::NewGuid().Guid
            }
        }

        # Mock Get-CUTriggerDetails. Deserialize from an existing XML file for consistency.
        Mock -CommandName Get-CUTriggerDetails -MockWith {
            try {
                $serializer = New-Object System.Runtime.Serialization.DataContractSerializer `
                                ([ControlUp.PowerShell.User.Cmdlets.Triggers.Data.TriggerDetails.AdvancedIncidentTriggerDetails])
                $fileStream = [System.IO.File]::OpenRead($triggerDetailsPath)
                $triggerDetailsTest = $serializer.ReadObject($fileStream)
            }
            finally {
                if ($fileStream) { $fileStream.Close() }
            }
            return $triggerDetailsTest
        }

        # Mock Get-CUObservableTriggerDetails to return a dummy observable trigger details object.
        Mock -CommandName Get-CUObservableTriggerDetails -MockWith {
            $observableDetails = [ControlUp.PowerShell.Common.Contract.ObservableTriggerService.GetObservableTriggerResponse]::New()
            $observableDetails.Table = "LogicalDisks"
            $observableDetails.Filters = @("FreeSpacePercentage", "DiskName")
            $observableDetails.Folders = @("MyOrg")
            return $observableDetails
        }

        # Mock Get-ScopedTriggerDump to return a sample record with appropriate properties.
        Mock -CommandName Get-ScopedTriggerDump -ModuleName TriggerTroubleshooter -MockWith {
            $guid = [Guid]::NewGuid().Guid
            return @{
                $guid = [PSCustomObject]@{
                    "FreeSpacePercentage" = 35.00
                    "Key"                 = $guid
                    "DiskName"            = "C:\"
                }
            }
        }

        # Mock Test-TriggerFilterNode similarly to use deserialization from the XML file.
        Mock -CommandName Test-TriggerFilterNode -ModuleName TriggerTroubleshooter -MockWith {
            try {
                $serializer = New-Object System.Runtime.Serialization.DataContractSerializer ([TriggerFilterResult])
                $fileStream = [System.IO.File]::OpenRead($triggerFilterResultsPath)
                $triggerFilterResult = $serializer.ReadObject($fileStream)
            }
            finally {
                if ($fileStream) { $fileStream.Close() }
            }
            return $triggerFilterResult
        }

        # Additional mocks for related functions used by Test-Trigger.
        Mock -CommandName Test-Schedule -ModuleName TriggerTroubleshooter -MockWith { return $true }
        Mock -CommandName Get-TableName -ModuleName TriggerTroubleshooter -MockWith { return "TestTable" }
        Mock -CommandName Test-ObserverdProperties -ModuleName TriggerTroubleshooter -MockWith { return $true }
    }

    Context "When the trigger is not found" {
        It "Should return null or empty output" {
            $result = Test-Trigger -Name "ThisIsNotARealTrigger" -WarningAction SilentlyContinue
            $result | Should BeNullOrEmpty
        }
    }

    Context "When the trigger exists" {
        It "Should return a valid TriggerFilterResult object" {
            $result = Test-Trigger -Name "ValidTrigger"
            $result | Should Not BeNullOrEmpty
            # Check that we have an array of results with the expected type.
            @($result).GetType().Name | Should Be "Object[]"
            if (@($result).Count -gt 0) {
                # Expect the EvaluationResult property to match either True or False
                @($result)[0].EvaluationResult.ToString() | Should Match "^(True|False)$"
            }
        }
    }
}

Write-Host "Pester tests completed."