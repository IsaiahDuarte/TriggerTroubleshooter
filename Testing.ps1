param (
    [Parameter(Mandatory=$true)]
    [string]$triggerName
)

try {
    $path = Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending
    if(!$path) {
        throw "Unable to find dll"
    }
    Import-Module $path
    Import-Module "$PSScriptRoot\TriggerTroubleshooter\TriggerTroubleshooter.psd1" -Force
    $results = Test-Trigger -Name $triggerName -ErrorAction Stop
    $results
} catch {
    throw $_
}