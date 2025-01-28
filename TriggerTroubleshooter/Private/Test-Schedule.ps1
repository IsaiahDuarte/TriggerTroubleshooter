<#
    .SYNOPSIS
        Tests whether a schedule is active at the current time.

    .DESCRIPTION
        The Test-Schedule function checks if a specified schedule is active at the current time.
        You can specify the schedule by name or by ID. If multiple schedules with the same name
        exist, an error is thrown when using the ScheduleName parameter.

    .PARAMETER ScheduleName
        The name of the schedule to test. If multiple schedules with the same name exist, an error is thrown.

    .PARAMETER ScheduleID
        The ID of the schedule to test.

    .EXAMPLE
        Test-Schedule -ScheduleName "Nightly Backup"

        Tests if the schedule named "Nightly Backup" is active at the current time.
#>
function Test-Schedule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ParameterSetName='ByName')]
        [string]$ScheduleName,

        [Parameter(Mandatory=$true, ParameterSetName='ByID')]
        [string]$ScheduleID
    )
   
    $now = Get-Date
    $currentDay = [int]$now.DayOfWeek
    $currentHour = $now.Hour
   
    $schedule = switch ($PSCmdlet.ParameterSetName) {
        'ByName' {
            $schedules = Get-CUTriggerSchedules | Where-Object { $_.Name -eq $ScheduleName }
            if ($schedules.Count -eq 0) {
                throw "Schedule '$ScheduleName' not found."
            } elseif ($schedules.Count -gt 1) {
                throw "Multiple schedules found with name '$ScheduleName'. Please specify by ScheduleID."
            } else {
                $schedules[0]
            }
        }
        'ByID' {
            $schedule = Get-CUTriggerSchedules | Where-Object { $_.Id -eq $ScheduleID }
            if (-not $schedule) {
                throw "Schedule with ID '$ScheduleID' not found."
            }
            $schedule
        }
    }
   
    $selectedHoursEntry = $schedule.Weekdays | Where-Object { $_.Day -eq $currentDay }
   
    if (-not $selectedHoursEntry) {
        return $false
    }
   
    $selectedHours = $selectedHoursEntry.SelectedHours
    $hourMask = 1 -shl $currentHour
    $isHourSelected = ($selectedHours -band $hourMask) -ne 0
   
    return $isHourSelected
}