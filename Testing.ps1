try {
    $triggerName = "Simple Logical Disk2"
    $path = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending
    if(!$path) {
        throw "Unable to find dll"
    }
    Import-Module $path
    Import-Module "$PSScriptRoot\TriggerTroubleshooter\TriggerTroubleshooter.psd1" -Force
    $result = Test-Trigger -Name $triggerName -ErrorAction Stop -Verbose -display
    Write-Host "Will trigger fire: $($result.EvaluationResult)"
} catch {
    throw $_
}