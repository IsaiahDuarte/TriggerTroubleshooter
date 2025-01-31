try {
    $ErrorActionPreference = 'Stop'
    $triggerName = "Service Advanced Trigger"

    $path = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending
    if(!$path) {
        throw "Unable to find dll"
    }

    Import-Module $path
    Import-Module "$PSScriptRoot\TriggerTroubleshooter\TriggerTroubleshooter.psd1" -Force

    $result = Test-Trigger -Name $triggerName -Verbose

    # Get-SupportTriggerDump -Name $triggerName 

    if($null -ne $result) {
        $result.DisplayResult()
    }
} catch {
    throw $_
}