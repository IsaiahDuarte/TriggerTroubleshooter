function Get-ScopedTriggerDump {
    [CmdletBinding(DefaultParameterSetName="Take")]
    param(
        [Parameter(Mandatory)]
        [string] $Name,
        
        [Parameter(Mandatory = $false, ParameterSetName = "Export")]
        [switch] $UseExport,

        [Parameter(Mandatory)]
        [ControlUp.PowerShell.Common.Contract.ObservableTriggerService.GetObservableTriggerResponse] $TriggerObservableDetails,

        [Parameter(Mandatory)]
        [string] $TriggerType,

        [Parameter(Mandatory = $false)]
        [string] $Table,

        [Parameter(Mandatory = $false)]
        [string[]] $Fields,

        [Parameter(Mandatory = $false, ParameterSetName = "Take")]
        [int] $Take = 100
    )
    
    Write-Verbose "Starting the Get-ScopedTriggerDump process for trigger: $Name"
    
    $tables = (Invoke-CUQuery -Scheme Information -Fields SchemaName, TableName -Table Tables -take 500).data.TableName
    Write-Verbose "Retrieved table names: $tables"

    if([string]::IsNullOrEmpty($Table)) {
        Write-Warning "Observable Details didn't return a table for $Name"
        return
    }


    if ($Table -notin $tables) {
        Write-Verbose "$Table not found in the list of tables."
        throw "Table was not found: $Table. If it is a built-in trigger or old one, export it, rename it, and import it"
    }

    Write-Verbose "$Table found. Proceeding to fetch data."

    $dump = @{}


    foreach ($folder in $triggerObservableDetails.Folders) {
        Write-Verbose "Processing folder: $folder"
        $splat = @{
            Table = $Table
            Fields = $triggerObservableDetails.Filters
            Where = "FolderPath='$folder'"
        }

        if($PSCmdlet.ParameterSetName -eq "Export") {
            $splat.UseExport = $UseExport
        }

        if($PSCmdlet.ParameterSetName -eq "Take") {
            $splat.Take = $Take
        }

        if($TriggerType -eq "UserLoggedOff") {
            Write-Verbose "UserLoggedOff trigger fields: $Fields"
            $splat.Fields = $Fields
        }

        $results = Get-CUQueryData @splat

        foreach ($item in $results) {
            Write-Verbose "Adding item with key: $($item.key) to the dump."
            $dump[$item.key] = $item
        }
    }

    Write-Verbose "Data collection complete. Returning the dump."
    return $dump
}