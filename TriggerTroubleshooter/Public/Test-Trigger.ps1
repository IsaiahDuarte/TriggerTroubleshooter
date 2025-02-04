function Test-Trigger {
    <#
    .SYNOPSIS
        Tests and retrieves trigger data based on the provided trigger name and related parameters. 

    .DESCRIPTION
        This function retrieves a trigger by its name, fetches detailed configuration information,
        and then uses a schedule test along with testing for observed properties. Depending on the 
        parameters provided, it executes a query or export operation to retrieve related data. 
        Finally, it runs a test on each record retrieved and outputs the results.

    .PARAMETER Name
        The name of the trigger to search for. This parameter is mandatory.

    .PARAMETER Display
        A switch parameter. If specified, the formatted results will be displayed.

    .PARAMETER UseExport
        A boolean value to indicate whether to use export mode when retrieving trigger dump details.
        Only valid for the "UseExport" parameter set.

    .PARAMETER RecordsPerFolder
        The number of records to retrieve per folder (applies to the "UseQuery" parameter set).
        Defaults to 100.

    .EXAMPLE
        Test-Trigger -Name "SampleTrigger" -Display
        Retrieves trigger details for "SampleTrigger" and displays the result.
    #>
    [CmdletBinding(DefaultParameterSetName = "UseQuery")]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [switch] $Display,

        [Parameter(Mandatory = $false, ParameterSetName = "UseExport")]
        [bool] $UseExport,

        [Parameter(Mandatory = $false, ParameterSetName = "UseQuery")]
        [int] $RecordsPerFolder = 100
    )

    try {
        Write-Verbose "Starting Test-Trigger for trigger name: $Name"
        $output = [System.Collections.Generic.List[TriggerFilterResult]]::New()

        Write-Verbose "Getting Trigger"
        $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $Name }
        if (-not $trigger) {
            Write-Warning "Trigger with name '$Name' not found."
            return
        }
        Write-Verbose "Trigger found: $trigger"

        Write-Verbose "Getting trigger configuration"
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId

        Write-Verbose "Testing the schedule"
        $scheduleResult = Test-Schedule -ScheduleID $triggerDetails.IncidentScheduleId

        Write-Verbose "Getting Trigger Observable Details"
        $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name

        Write-Verbose "Getting the Table"
        $table = Get-TableName -Name $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType

        Write-Verbose "Testing if properties are in the Observables runtime"
        $arePropertiesObserved = Test-ObserverdProperties -ResourceName $table -Properties $triggerDetails.FilterNodes.ExpressionDescriptor.Column

        Write-Verbose "Getting trigger dump"
        $dumpSplat = @{
            Name                     = $Name
            Fields                   = $triggerDetails.FilterNodes.ExpressionDescriptor.Column
            Table                    = $table
            TriggerObservableDetails = $triggerObservableDetails
            TriggerType              = $triggerDetails.TriggerType
        }

        if ($PSCmdlet.ParameterSetName -eq "UseExport") {
            $dumpSplat.UseExport = $UseExport
        }

        if ($PSCmdlet.ParameterSetName -eq "UseQuery") {
            $dumpSplat.Take = $RecordsPerFolder
        }

        $dump = Get-ScopedTriggerDump @dumpSplat

        if ($dump.Count -eq 0) {
            Write-Warning "No data was returned by the query."
            return
        }

        Write-Verbose "Data retrieved from Get-ScopedTriggerDump: $($dump.Count) records found."

        Write-Verbose "Testing each entry from dump"
        foreach ($key in $dump.Keys) {
            Write-Verbose "Testing $key"
            $record = $dump[$key]
            $rootNode = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::New()
            $rootNode.ChildNodes = $triggerDetails.FilterNodes

            $result = Test-TriggerFilterNode -Node $rootNode -Record $record
            $result.ScheduleResult = $scheduleResult
            $result.ArePropertiesObserved = $arePropertiesObserved
            [void] $output.Add($result)
        }

        Write-Verbose "Returning output with $($output.Count) records."

        if ($Display) {
            $output.DisplayResult()
        }

        return $output
    }
    catch {
        Write-Error -Message "Error in Test-Trigger: $($_.Exception.Message)" -ErrorAction Stop
    }

} 