

# if( ! ( $cuMonitorService = Get-CimInstance -ClassName win32_service -Filter "Name = 'cuMonitor'" ) )
# {
#     Throw "Unable to find the ControlUp Monitor service which is required for this script to run"
# }

# [string]$cudll = Join-Path -Path (Split-Path -Path ($cuMonitorService.PathName -replace '"') -Parent) -ChildPath 'ControlUp.PowerShell.User.dll'

Set-StrictMode -Version Latest
$path = (Get-ChildItem "C:\Program Files\Smart-X\ControlUpMonitor\*\ControlUp.Powershell.User.dll" | Sort-Object -Property LastAccessTime -Descending)[0]
if (!$path) {
    throw "Unable to find dll"
}

Import-Module $path
$rootPath = Split-Path -Path $PSScriptRoot
Import-Module "$rootPath\src\TriggerTroubleshooter.psd1" -Force


#Trace-TriggerData -Name "Logical Disk Advanced Trigger" -Verbose -Duration (New-TimeSPan -Seconds 2)
# $a = Invoke-SimulatedWindowsEvent -TriggerName 'WEvent' -ComputerName 'OLIVER-RT' -Verbose
# $b = Invoke-SimulatedMemoryUsage -TriggerName "Memory" -ComputerName "OLIVER-RT" -Verbose
#$c = Invoke-SimulatedTrigger -TriggerName "CPU" -ComputerName "oliver-rt" -ConditionType "CPU" -Verbose
Get-CUTriggers -IsEnabled $true | Foreach-Object {
    if ($_.TriggerName -like 'Logical Disk Advanced Trigger' ) { 
        Write-Output "`n`nProcessing Trigger $($_.TriggerName)"
        $result = Test-Trigger -Name $_.TriggerName -Verbose -AllRecords
        
        if ($null -ne $result) {
            $result.DisplayResult()
        }

        Get-SupportTriggerDump -Name $_.TriggerName
    }
}