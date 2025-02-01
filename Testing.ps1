$path = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending
if(!$path) {
    throw "Unable to find dll"
}

Import-Module $path
Import-Module "$PSScriptRoot\TriggerTroubleshooter\TriggerTroubleshooter.psd1" -Force

Get-CUTriggers -IsEnabled $true | Foreach-Object {
    Write-host "`n`nProcessing Trigger $($_.TriggerName)" -ForegroundColor Blue
    $result = Test-Trigger -Name $_.TriggerName -UseExport $false -Verbose
    
    if($null -ne $result -and $_.TriggerName -notlike "*process*") {
        $result.DisplayResult()
    }
}
