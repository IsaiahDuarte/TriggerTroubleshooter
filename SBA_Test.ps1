param (
    [Parameter(Mandatory)]
    [string] $TriggerName,

    [Parameter(Mandatory=$false)]
    [ValidateSet("False","Trues")]
    [string] $UseExport
)

Write-Host "Importing latest module from monitor"
$pathToUserModule = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*ControlUp.PowerShell.User.dll" -Recurse | Sort-Object LastWriteTime -Descending)[0]
Import-Module $pathToUserModule

Write-host "Importing TriggerTroubleshooter module"
Import-Module "C:\Users\izzy\Desktop\TriggerTroubleshooter\TriggerTroubleshooter\TriggerTroubleshooter.psd1"

Write-Host "`nTesting $TriggerName"
$result = Test-Trigger -Name $TriggerName -UseExport ($UseExport -eq "True")

Write-Host "`nTested $($result.count) recrods against trigger conditions"

$result.DisplayResult()