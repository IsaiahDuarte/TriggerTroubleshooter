BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1').Replace('tests','src').Replace('\unit','')
    function Get-CUTriggerSchedules { }

    function Write-TriggerTroubleshooterLog { }
}

Describe "Test-Schedule" {

    Context "Using parameter set 'ByName'" {

        It "returns true when the current hour is active" {
            $now         = Get-Date
            $currentDay  = [int]$now.DayOfWeek
            $currentHour = $now.Hour
            $currentMask = 1 -shl $currentHour

            $weekdayEntry = [PSCustomObject]@{
                Day           = $currentDay
                SelectedHours = $currentMask
            }
            $testSchedule = [PSCustomObject]@{
                Id       = "TestID"
                Name     = "WorkingHours"
                WeekDays = @($weekdayEntry)
            }
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@($testSchedule) }

            $result = Test-Schedule -ScheduleName "WorkingHours"
            $result | Should -BeTrue
        }

        It "returns false when the current hour is not active" {
            $now         = Get-Date
            $currentDay  = [int]$now.DayOfWeek
            $weekdayEntry = [PSCustomObject]@{
                Day           = $currentDay
                SelectedHours = 0
            }
            $testSchedule = [PSCustomObject]@{
                Id       = "TestID"
                Name     = "OffHours"
                WeekDays = @($weekdayEntry)
            }
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@($testSchedule) }

            $result = Test-Schedule -ScheduleName "OffHours"
            $result | Should -BeFalse
        }

        It "writes an error if no schedule is found" {
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@() }

            $errors = & { Test-Schedule -ScheduleName "NonExistent" } 2>&1
            $errors.Exception.Message | Should -Be "Error in Test-Schedule: Schedule 'NonExistent' not found."
        }

        It "writes an error if multiple schedules are found" {
            $sched1 = [PSCustomObject]@{
                Id       = "ID1"
                Name     = "DuplicateSchedule"
                WeekDays = @()
            }
            $sched2 = [PSCustomObject]@{
                Id       = "ID2"
                Name     = "DuplicateSchedule"
                WeekDays = @()
            }
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@($sched1, $sched2) }

            $errors = & { Test-Schedule -ScheduleName "DuplicateSchedule" } 2>&1
            $errors | Should -Match "Multiple schedules found with name 'DuplicateSchedule'. Please specify by ScheduleID."
        }
    }

    Context "Using parameter set 'ByID'" {

        It "returns true when the current hour is active" {
            $now         = Get-Date
            $currentDay  = [int]$now.DayOfWeek
            $currentHour = $now.Hour
            $currentMask = 1 -shl $currentHour

            $weekdayEntry = [PSCustomObject]@{
                Day           = $currentDay
                SelectedHours = $currentMask
            }
            $testSchedule = [PSCustomObject]@{
                Id       = "ID-123"
                Name     = "AnyName"
                WeekDays = @($weekdayEntry)
            }
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@($testSchedule) }

            $result = Test-Schedule -ScheduleID "ID-123"
            $result | Should -BeTrue
        }

        It "returns false when the current hour is not active" {
            $now         = Get-Date
            $currentDay  = [int]$now.DayOfWeek

            $weekdayEntry = [PSCustomObject]@{
                Day           = $currentDay
                SelectedHours = 0
            }
            $testSchedule = [PSCustomObject]@{
                Id       = "ID-456"
                Name     = "AnyName"
                WeekDays = @($weekdayEntry)
            }
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@($testSchedule) }

            $result = Test-Schedule -ScheduleID "ID-456"
            $result | Should -BeFalse
        }

        It "writes an error when the schedule ID is not found" {
            Mock -CommandName Get-CUTriggerSchedules -MockWith { $null }

            $errors = & { Test-Schedule -ScheduleID "ID-NotFound" } 2>&1
            $errors | Should -Match "Schedule with ID 'ID-NotFound' not found."
        }

        It "returns true using the first schedule when ScheduleID is 'All Days'" {
            $now         = Get-Date
            $currentDay  = [int]$now.DayOfWeek
            $currentHour = $now.Hour
            $currentMask = 1 -shl $currentHour

            $weekdayEntry = [PSCustomObject]@{
                Day           = $currentDay
                SelectedHours = $currentMask
            }
            $sched1 = [PSCustomObject]@{
                Id       = "All Days"
                Name     = "ScheduleAllDays"
                WeekDays = @($weekdayEntry)
            }
            $sched2 = [PSCustomObject]@{
                Id       = "All Days"
                Name     = "ScheduleAllDays-Second"
                WeekDays = @()  # Not used since the first is selected.
            }
            Mock -CommandName Get-CUTriggerSchedules -MockWith { ,@($sched1, $sched2) }

            $result = Test-Schedule -ScheduleID "All Days"
            $result | Should -BeTrue
        }
    }
}