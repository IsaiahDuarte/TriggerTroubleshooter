function Get-ScopedTriggerDump {
    <#
        .SYNOPSIS
            Retrieves scoped trigger dump data for the specified trigger. 

        .DESCRIPTION
            This function retrieves trigger dump data by querying a specified table based on the trigger's
            observable details. It iterates over provided folders in the observable details, executes a query 
            for each folder, and collates the returned data into a hash table.

        .PARAMETER Name
            The name of the trigger.

        .PARAMETER TriggerObservableDetails
            The trigger observable details object, type of
            ControlUp.PowerShell.Common.Contract.ObservableTriggerService.GetObservableTriggerResponse.

        .PARAMETER TriggerType
            The type of the trigger (e.g. "UserLoggedOff").

        .PARAMETER Table
            The name of the table to query.

        .PARAMETER Fields
            An array of fields to be retrieved from TriggerDetails.FilterNodes.ExpressionDescriptor.Column but may be
            ignored if they are returned by observable details.
        
        .PARAMETER SkipTableValidation
            When specified it won't verify the table exists.

        .PARAMETER Take
            The maximum number of records to retrieve. Defaults to 100.
    
        .PARAMETER TakeAll
            A switch used to get all data

        .EXAMPLE
            Get-ScopedTriggerDump -Name "SampleTrigger" -TriggerObservableDetails $obsDetails -TriggerType "UserLoggedOff" -Table "Sessions" -Take 100
    #>
    [CmdletBinding(DefaultParameterSetName = "Take")]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [ControlUp.PowerShell.Common.Contract.ObservableTriggerService.GetObservableTriggerResponse] $TriggerObservableDetails,

        [Parameter(Mandatory = $true)]
        [string] $TriggerType,

        [Parameter(Mandatory = $false)]
        [string] $Table,

        [Parameter(Mandatory = $false)]
        [string[]] $Fields,

        [Parameter(Mandatory = $false)]
        [switch] $SkipTableValidation,

        [Parameter(Mandatory = $false, ParameterSetName = "Take")]
        [int] $Take = 100,

        [Parameter(Mandatory = $false, ParameterSetName = "TakeAll")]
        [switch] $TakeAll
    )

    try {
        Write-Verbose "Starting the Get-ScopedTriggerDump process for trigger: $Name"

        if(!$SkipTableValidation) {
            $tables = (Invoke-CUQuery -Scheme Information -Fields SchemaName, TableName -Table Tables -take 500).data.TableName | Sort-Object
            Write-Verbose "Retrieved table names: $tables"
    
            if ([string]::IsNullOrEmpty($Table)) {
                Write-Warning "Observable Details didn't return a table for $Name"
                return
            }
    
            if ($Table -notin $tables) {
                Write-Verbose "$Table not found in the list of tables."
                throw "Table was not found: $Table. If it is a built-in trigger or old one, export it, rename it, and import it."
            }
        }

        Write-Verbose "$Table found. Proceeding to fetch data."

        $dump = @{}

        Write-Verbose "Building Query"
        $where = ""
        foreach($folder in $TriggerObservableDetails.Folders) {
            # FolderPath is empty on Folder objects. Use Path.
            if($TriggerObservableDetails.Table -eq "Folders") {
                $where = "${where}Path='$folder' OR"
            } else {
                $where = "${where}FolderPath='$folder' OR "
            }
        }

        $where = $where.TrimEnd(" OR ")

        Write-Verbose "Query: $Where"

        $splat = @{
            Table  = $Table
            Fields = $TriggerObservableDetails.Filters
            Where  = $where
        }

        if ($PSCmdlet.ParameterSetName -eq "TakeAll") {
            $splat.TakeAll = $TakeAll
        }
        
        if ($PSCmdlet.ParameterSetName -eq "Take") {
            $splat.Take = $Take
        }

        $NoTableTypes = @("UserLoggedOff", "UserLoggedOn", "WindowsEvent", "ProcessStarted", "ProcessEnded", "MachineDown", "SessionStateChanged")
        if ($TriggerType -in $NoTableTypes) {
            Write-Verbose "Trigger is one of the following that doesn't return data from TriggerObservableDetails: $NoTableTypes. overriding fields with: $Fields"
            $splat.Fields = $Fields
        }

        # Gives an identifier for a record like sName based on the table
        $identityField = Get-IdentityPropertyFromTable -Table $Table
        if(![string]::IsNullOrEmpty($identityField) -and $identityField -notin $splat.Fields) {
            $splat.Fields += $identityField
        }

        $results = Get-CUQueryData @splat

        # We need to adjust the data if its a WindowsEvent
        if($TriggerType -eq "WindowsEvent" -and $null -ne $results) {
            $results = Set-WindowsEventData -Data $results
        }

        foreach ($item in $results) {
            Write-Verbose "Adding item with key: $($item.key) to the dump."
            $dump[$item.key] = $item
        }

        Write-Verbose "Data collection complete. Returning dump."
        return $dump
    }
    catch {
        Write-Error "Error in Get-ScopedTriggerDump: $($_.Exception.Message)"
        throw $_.Exception.Message
    }
} 