<#
    .SYNOPSIS
    Retrieves a dump of scoped trigger data based on a trigger name.

    .DESCRIPTION
    The Get-ScopedTriggerDump function performs a query to obtain trigger details and validates the existence of associated tables. It iterates through folder data and compiled results, collecting those which match the trigger specifications.

    .PARAMETER name
    The name of the scoped trigger for which to collect the data dump.

    .EXAMPLE

    .NOTES
    Relies on other functions such as Invoke-CUQuery for querying the database and Get-TableName for table validation.
#>
function Get-ScopedTriggerDump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $name
    )
    $tables = (Invoke-CUQuery -Scheme Information -Fields SchemaName, TableName -Table Tables).data.TableName

    $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $triggerName
    $table = Get-TableName -Name $triggerObservableDetails.Table

    if($table -notin $tables) {
        throw "Table was not found: $table. If it is an built-in trigger or old one, export it, rename it, and import it"
    }

    $dump = @{}
    foreach($folder in $triggerObservableDetails.Folders) {
        $results = (Invoke-CUQuery -Table $table -Fields $triggerObservableDetails.Filters).Data
        foreach ($item in $results) {
            $dump[$item.key] = $item
        }
    }

    return $dump
}