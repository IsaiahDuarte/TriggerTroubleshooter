<#
    .SYNOPSIS
    Maps a given name to a corresponding table name.

    .DESCRIPTION

    .PARAMETER name

    .EXAMPLE

    .NOTES
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