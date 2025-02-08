Set-StrictMode -Version Latest
$path = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending)[0]
if (!$path) {
    throw "Unable to find dll"
}

Import-Module $path
Import-Module "$PSScriptRoot\TriggerTroubleshooter\TriggerTroubleshooter.psd1" -Force

Get-CUTriggers -IsEnabled $true | Foreach-Object {
    if ($_.TriggerName -eq 'RegexNotWorkingOnSomeColumns' ) { 
        Write-Output "`n`nProcessing Trigger $($_.TriggerName)"
        $result = Test-Trigger -Name $_.TriggerName -UseExport
        
        if ($null -ne $result) {
            $result.DisplayResult()
        }

        Get-SupportTriggerDump -Name $_.TriggerName
    }
}