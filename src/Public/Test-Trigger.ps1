function Test-Trigger {
    <#
    .SYNOPSIS
        Tests a trigger by name and performs configuration checks and property testing. 

    .DESCRIPTION
        This function retrieves a trigger by its name, fetches its configuration, and then test the schedule
        along with testing if the properties are observed by the monitor. Depending on the 
        parameters provided, it uses invoke-cuquery or export-cuquery to obtain data. 
        It tests each record againts the trigger configuration and optionally outputs the results.

    .PARAMETER Name
        The name of the trigger to search for.

    .PARAMETER Display
        A switch parameter. If specified, the formatted results will be displayed.

    .PARAMETER AllRecords
        A switch used to get all available data

    .PARAMETER Records
        The number of records to process

    .EXAMPLE
        Test-Trigger -Name "SampleTrigger" -Display
        Retrieves trigger details for "SampleTrigger" and displays the result.
    #>
    [CmdletBinding(DefaultParameterSetName = "Records")]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [switch] $Display,

        [Parameter(Mandatory = $false, ParameterSetName = "AllRecords")]
        [switch] $AllRecords,

        [Parameter(Mandatory = $false, ParameterSetName = "Records")]
        [int] $Records = 10
    )

    try {
        Write-TTLog "Starting Test-Trigger for trigger name: $Name"
        $output = [System.Collections.Generic.List[TriggerFilterResult]]::New()

        Write-TTLog "Getting Trigger"
        $trigger = Get-Trigger -Name $Name
        if (-not $trigger) {
            Write-Warning "Trigger with name '$Name' not found."
            return
        }
        Write-TTLog "Trigger found: $trigger"

        Write-TTLog "Getting trigger configuration"
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.Id

        Write-TTLog "Testing the schedule"
        $scheduleResult = Test-Schedule -ScheduleID $triggerDetails.IncidentScheduleId

        Write-TTLog "Getting Trigger Observable Details"
        $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name

        # Sometimes when a trigger is disabled, then gets enabled, Get-CUObservableTriggerDetails returns empty filter/table
        if($triggerObservableDetails.Filters.Count -eq 0) {
            $triggerObservableDetails.Filters = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes
        }

        if([string]::IsNullOrEmpty($triggerObservableDetails.Table)) {
            $triggerObservableDetails.Table = $triggerDetails.TableName
        }

        Write-TTLog "Getting the Table"
        $table = Get-TableName -TableName $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType

        Write-TTLog "Getting all columns"
        $columns = Get-TriggerColumns -FilterNodes $triggerDetails.FilterNodes

        Write-TTLog "Testing if properties are in the Observables runtime"
        $arePropertiesObserved = Test-ObserverdProperties -ResourceName $table -Properties $columns

        Write-TTLog "Getting trigger dump"
        $dumpSplat = @{
            Name                     = $Name
            Fields                   = $columns
            Table                    = $table
            TriggerObservableDetails = $triggerObservableDetails
            TriggerType              = $triggerDetails.TriggerType
        }

        if ($PSCmdlet.ParameterSetName -eq "AllRecords") {
            Write-TTLog "AllRecords found"
            $dumpSplat.TakeAll = $AllRecords
        }

        if ($PSCmdlet.ParameterSetName -eq "Records") {
            Write-TTLog "Records found"
            $dumpSplat.Take = $Records
        }

        $dump = Get-ScopedTriggerDump @dumpSplat
        if ($dump.Count -eq 0) {
            Write-Warning "No data was returned by the query."
            return
        }

        $identityField = Get-IdentityPropertyFromTable -Table $table
        Write-TTLog "Identity Field: $identityField"

        $lastInspectionTime = [datetime](Invoke-CUQuery -Scheme Runtime -Table TriggersRuntime -Fields LastInspection -Where "Id='$($trigger.ID)'").data.LastInspection

        Write-TTLog "Data retrieved from Get-ScopedTriggerDump: $($dump.Count) records found."

        Write-TTLog "Testing each entry from dump"
        foreach ($key in $dump.Keys) {
            Write-TTLog "Testing $key"
            $record = $dump[$key]
            $rootNode = [ControlUp.PowerShell.Common.Contract.Triggers.TriggerFilterNode]::New()
            $rootNode.ChildNodes = $triggerDetails.FilterNodes

            $result = Test-TriggerFilterNode -Node $rootNode -Record $record
            $result.ScheduleResult = $scheduleResult
            $result.IdentityField = $record."$identityField"
            $result.ArePropertiesObserved = $arePropertiesObserved
            $result.LastInspectionTime = $lastInspectionTime
            [void] $output.Add($result)
        }

        Write-TTLog "Returning output with $($output.Count) records."

        if ($Display) {
            $output.DisplayResult()
        }
        
        # Force output to be TriggerFilterResult[]
        , $output.ToArray()
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error -Message "Error in Test-Trigger: $($_.Exception.Message)" -ErrorAction Stop
    }
} 