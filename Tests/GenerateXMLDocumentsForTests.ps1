# This script generates XML files which are used by Test-Trigger.Tests.ps1.
# It first loads the required ControlUp assembly and module, then retrieves a specific trigger,
# serializes its details and trigger filter results, and writes them to XML files.
# This is to be used for Pester tests. 

[CmdletBinding()]
param (
    # Optionally you could specify the trigger name, otherwise "ValidTrigger" is used.
    [string]$TriggerName = "ValidTrigger"
)

# Load the DataContract Serialization assembly.
Add-Type -AssemblyName System.Runtime.Serialization

function Get-ControlUpDll {
    $dllPath = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" |
        Sort-Object LastAccessTime -Descending |
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

# Import the ControlUp user module from the DLL.
Import-ControlUpUserModule

# Determine paths relative to this script.
$basePath = Split-Path -Path $PSScriptRoot
# Change the relative path as needed. In this example, the Unit folder should exist under the script folder.
$triggerDetailsPath = Join-Path -Path $PSScriptRoot -ChildPath "Unit\Test-Trigger.tests.TriggerDetails.xml"
$triggerFilterResultsPath = Join-Path -Path $PSScriptRoot -ChildPath "Unit\Test-Trigger.tests.TriggerFilterResult.xml"

# Load the TriggerTroubleshooter module from the repository.
$modulePath = Join-Path -Path $basePath -ChildPath "TriggerTroubleshooter\TriggerTroubleshooter.psd1"
Import-Module $modulePath -Force -ErrorAction Stop

# Retrieve the trigger using Get-CUTriggers.
$trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $TriggerName }
if (-not $trigger) {
    Write-Warning "Trigger with name '$TriggerName' not found. Please ensure it is in the ControlUp configuration."
    return
}

# Retrieve trigger details based on the found trigger.
$triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId

# Serialize trigger details to XML.
try {
    $serializer = New-Object System.Runtime.Serialization.DataContractSerializer `
                    ([ControlUp.PowerShell.User.Cmdlets.Triggers.Data.TriggerDetails.AdvancedIncidentTriggerDetails])
    $fileStream = [System.IO.File]::Create($triggerDetailsPath)
    $serializer.WriteObject($fileStream, $triggerDetails)
}
finally {
    if ($fileStream) { $fileStream.Close() }
}
Write-Host "Serialized trigger details to: $triggerDetailsPath"

# Retrieve trigger observable details.
$triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $TriggerName

# Prepare splatted parameters for Get-ScopedTriggerDump.
$dumpSplat = @{
    Name                     = $TriggerName
    Fields                   = $triggerDetails.FilterNodes.ExpressionDescriptor.Column
    Table                    = Get-TableName -TableName $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType
    TriggerObservableDetails = $triggerObservableDetails
    TriggerType              = $triggerDetails.TriggerType
    Take                     = 1
}
$recordDump = Get-ScopedTriggerDump @dumpSplat

# For this example, take the first record key and create the root filter node.
$rootNode = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::New()
$rootNode.ChildNodes = $triggerDetails.FilterNodes

# Test the trigger filter node using the module's function.
$result = Test-TriggerFilterNode -Node $rootNode -Record ($recordDump.Values | Select-Object -First 1)

# Serialize the trigger filter result to XML.
try {
    $serializer = New-Object System.Runtime.Serialization.DataContractSerializer ([TriggerFilterResult])
    $fileStream = [System.IO.File]::Create($triggerFilterResultsPath)
    $serializer.WriteObject($fileStream, $result)
}
finally {
    if ($fileStream) { $fileStream.Close() }
}
Write-Host "Serialized trigger filter result to: $triggerFilterResultsPath"

Write-Host "XML generation completed successfully."