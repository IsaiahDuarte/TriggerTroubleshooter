<#
    .SYNOPSIS
    Maps a given name to a corresponding table name.

    .DESCRIPTION
    The Get-TableName function takes a name parameter and maps it to a predefined table name using a switch statement. If no mapping is found, it returns the name itself or a default message.

    .PARAMETER name
    The input name to be mapped to a table name.

    .EXAMPLE

    .NOTES
    This function helps manage name-to-table mappings within the context of observable details.
#>
function Get-TableName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $name
    )

    $table = ""
    switch($name) {
        "ComputerView"    { $table = "Computers" }
        "Services"        { $table = "'$($name)' not implemented" }
        "SessionsView"    { $table = "Sessions" }
        ""                { $table = "Not returned by observable details"}
        Default           { $table = $name }
    }

    return $table
}