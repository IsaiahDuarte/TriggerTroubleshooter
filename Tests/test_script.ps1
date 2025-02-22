Set-StrictMode -Version Latest
$path = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending)[0]
if (!$path) {
    throw "Unable to find dll"
}

Import-Module $path
$rootPath = Split-Path -Path $PSScriptRoot
Import-Module "$rootPath\src\TriggerTroubleshooter.psd1" -Force

# Trace-TriggerData -Name "Logical Disk Advanced Trigger" -Verbose
Get-CUTriggers -IsEnabled $true | Foreach-Object {
    if ($_.TriggerName -eq 'Logical Disk Advanced Trigger' ) { 
        Write-Output "`n`nProcessing Trigger $($_.TriggerName)"
        $result = Test-Trigger -Name $_.TriggerName -Verbose -AllRecords
        
        if ($null -ne $result) {
            $result.DisplayResult()
        }

        Get-SupportTriggerDump -Name $_.TriggerName
    }
}