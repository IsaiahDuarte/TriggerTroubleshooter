function Test-Schedule {
    <#
        .SYNOPSIS
            Tests whether the current hour falls within a trigger schedule. 
            
        .DESCRIPTION
            This function retrieves a schedule either by its name or ID, then determines if the
            current day and hour are active within that schedule. It uses the schedule's weekday
            information and a bitmask for the current hour to determine if the current hour is set
            as active.

        .PARAMETER ScheduleName
            The name of the schedule to retrieve. Used only when the parameter set is 'ByName'.

        .PARAMETER ScheduleID
            The ID of the schedule to retrieve. Used only when the parameter set is 'ByID'.

        .EXAMPLE
            Test-Schedule -ScheduleName "WorkingHours"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string] $ScheduleName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByID')]
        [string] $ScheduleID
    )

    try {
        Write-TTLog "Starting Test-Schedule. ParameterSetName: $($PSCmdlet.ParameterSetName)"
        $now = [datetime]::Now
        $currentDay = [int]$now.DayOfWeek
        $currentHour = $now.Hour
        Write-TTLog "Current Day: $currentDay, Current Hour: $currentHour"

        $schedule = switch ($PSCmdlet.ParameterSetName) {
            'ByName' {
                Write-TTLog "Retrieving schedule by name: $ScheduleName"
                $schedules = Get-CUTriggerSchedules

                if ($null -eq $schedules) {
                    throw "Get-CUTriggerSchedules returned nothing"
                }

                $schedules = $schedules | Where-Object { $_.Name -eq $ScheduleName }
                if ($schedules.Count -eq 0) {
                    throw "Schedule '$ScheduleName' not found."
                }
                elseif ($schedules.Count -gt 1) {
                    throw "Multiple schedules found with name '$ScheduleName'. Please specify by ScheduleID."
                }
                else {
                    Write-TTLog "Found schedule: $($schedules[0])"
                    $schedules[0]
                }
            }
            'ByID' {
                Write-TTLog "Retrieving schedule by ID: $ScheduleID"
                $schedule = Get-CUTriggerSchedules | Where-Object { $_.Id -eq $ScheduleID }
                if (-not $schedule) {
                    throw "Schedule with ID '$ScheduleID' not found."
                }

                # For some reason this returns two; if ScheduleID is 'All Days' then pick the first
                if ($ScheduleID -eq "All Days") {
                    Write-TTLog "ScheduleID is 'All Days'; using first entry."
                    $schedule = $schedule[0]
                }
                Write-TTLog "Found schedule: $schedule"
                $schedule
            }
        }

        $selectedHoursEntry = $schedule.Weekdays | Where-Object { $_.Day -eq $currentDay }
        Write-TTLog "Selected hours entry for current day ($currentDay): $selectedHoursEntry"

        if (-not $selectedHoursEntry) {
            Write-TTLog "No entry found for current day; returning false."
            return $false
        }

        $selectedHours = $selectedHoursEntry.SelectedHours
        Write-TTLog "Selected hours for current day: $selectedHours"

        $hourMask = 1 -shl $currentHour
        Write-TTLog "Hour mask for current hour ($currentHour): $hourMask"

        $isHourSelected = ($selectedHours -band $hourMask) -ne 0
        Write-TTLog "Is current hour selected: $isHourSelected"

        return $isHourSelected
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Test-Schedule: $($_.Exception.Message)"
    }
} 