function Get-ScopedTriggerDump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )
    
    Write-Verbose "Starting the Get-ScopedTriggerDump process for trigger: $Name"
    
    $tables = (Invoke-CUQuery -Scheme Information -Fields SchemaName, TableName -Table Tables -take 200).data.TableName
    Write-Verbose "Retrieved table names: $tables"

    $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name

    if([string]::IsNullOrEmpty($triggerObservableDetails.Table)) {
        Write-Warning "Observable Details didn't return a table for $Name"
        return
    }
 
    Write-Verbose "Fetched trigger observable details: $triggerObservableDetails"

    $table = Get-TableName -Name $triggerObservableDetails.Table
    Write-Verbose "Resolved table name: $table"

    if ($table -notin $tables) {
        Write-Verbose "$table not found in the list of tables."
        throw "Table was not found: $table. If it is a built-in trigger or old one, export it, rename it, and import it"
    }

    Write-Verbose "$table found. Proceeding to fetch data."

    $dump = @{}
    foreach ($folder in $triggerObservableDetails.Folders) {
        Write-Verbose "Processing folder: $folder"
        $results = (Invoke-CUQuery -Table $table -Fields $triggerObservableDetails.Filters -Focus $folder).Data

        foreach ($item in $results) {
            Write-Verbose "Adding item with key: $($item.key) to the dump."
            $dump[$item.key] = $item
        }
    }

    Write-Verbose "Data collection complete. Returning the dump."
    return $dump
}