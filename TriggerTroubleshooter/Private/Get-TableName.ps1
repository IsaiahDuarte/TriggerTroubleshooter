function Get-TableName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    Write-Verbose "Getting table name for: $Name"

    $table = ""
    switch($Name) {
        ""                { 
            $table = "Not returned by observable details"
            Write-Verbose "No name provided; returning: $table"
        }
        Default           { 
            $table = $Name 
            Write-Verbose "No specific mapping found; returning the original name: $table"
        }
    }

    Write-Verbose "Returning table name: $table"
    return $table
}