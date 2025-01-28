<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER name

    .EXAMPLE

    .NOTES
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