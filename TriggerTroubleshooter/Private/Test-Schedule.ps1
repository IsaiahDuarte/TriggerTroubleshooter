function Test-Schedule {
    <#
    .SYNOPSIS
        Tests whether the current hour falls within the schedule for today. 
        
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
        This tests the schedule named "WorkingHours" for the current day and hour.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [string] $ScheduleName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByID')]
        [string] $ScheduleID
    )

    try {
        Write-Verbose "Starting Test-Schedule. ParameterSetName: $($PSCmdlet.ParameterSetName)"
        $now = Get-Date
        $currentDay = [int]$now.DayOfWeek
        $currentHour = $now.Hour
        Write-Verbose "Current Day: $currentDay, Current Hour: $currentHour"

        # Retrieve the schedule based on the parameter set provided
        $schedule = switch ($PSCmdlet.ParameterSetName) {
            'ByName' {
                Write-Verbose "Retrieving schedule by name: $ScheduleName"
                $schedules = Get-CUTriggerSchedules | Where-Object { $_.Name -eq $ScheduleName }
                if ($schedules.Count -eq 0) {
                    throw "Schedule '$ScheduleName' not found."
                }
                elseif ($schedules.Count -gt 1) {
                    throw "Multiple schedules found with name '$ScheduleName'. Please specify by ScheduleID."
                }
                else {
                    Write-Verbose "Found schedule: $($schedules[0])"
                    $schedules[0]
                }
            }
            'ByID' {
                Write-Verbose "Retrieving schedule by ID: $ScheduleID"
                $schedule = Get-CUTriggerSchedules | Where-Object { $_.Id -eq $ScheduleID }
                if (-not $schedule) {
                    throw "Schedule with ID '$ScheduleID' not found."
                }

                # For some reason this returns two; if ScheduleID is 'All Days' then pick the first
                if ($ScheduleID -eq "All Days") {
                    Write-Verbose "ScheduleID is 'All Days'; using first entry."
                    $schedule = $schedule[0]
                }
                Write-Verbose "Found schedule: $schedule"
                $schedule
            }
        }

        # Check for the selected hours for the current day within the schedule's weekdays info.
        $selectedHoursEntry = $schedule.Weekdays | Where-Object { $_.Day -eq $currentDay }
        Write-Verbose "Selected hours entry for current day ($currentDay): $selectedHoursEntry"

        if (-not $selectedHoursEntry) {
            Write-Verbose "No entry found for current day; returning false."
            return $false
        }

        $selectedHours = $selectedHoursEntry.SelectedHours
        Write-Verbose "Selected hours for current day: $selectedHours"

        # Create a bitmask for the current hour using left shift
        $hourMask = 1 -shl $currentHour
        Write-Verbose "Hour mask for current hour ($currentHour): $hourMask"

        # Determine if the current hour is active in the schedule by performing a bitwise AND
        $isHourSelected = ($selectedHours -band $hourMask) -ne 0
        Write-Verbose "Is current hour selected: $isHourSelected"

        return $isHourSelected
    }
    catch {
        Write-Error "Error in Test-Schedule: $($_.Exception.Message)"
    }
} 