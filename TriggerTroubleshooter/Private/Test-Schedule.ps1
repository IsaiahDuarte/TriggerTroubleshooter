<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER ScheduleName

    .PARAMETER ScheduleID

    .EXAMPLE

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

            # For some reason this returns two
            if($ScheduleID -eq "All Days") {
                $schedule = $Schedule[0]
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