try {
    $ErrorActionPreference = 'Stop'
    $triggerName = "_40605 - Trigger Issue"

    $path = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending
    if(!$path) {
        throw "Unable to find dll"
    }

    Import-Module $path
    Import-Module "$PSScriptRoot\TriggerTroubleshooter\TriggerTroubleshooter.psd1" -Force

    $result = Test-Trigger -Name $triggerName

    Get-SupportTriggerDump -Name $triggerName -Verbose

    if($null -ne $result) {
        $result[0].DisplayResult()
    }
} catch {
    throw $_
}