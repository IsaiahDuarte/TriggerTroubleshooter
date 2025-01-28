function Get-TableName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $name
    )

    Write-Verbose "Getting table name for: $name"

    $table = ""
    switch($name) {
        "ComputerView"    { 
            $table = "Computers"
            Write-Verbose "Mapped $name to $table"
        }
        "Services"        { 
            $table = "'$($name)' not implemented" 
            Write-Verbose "Table for $name is not implemented."
        }
        "SessionsView"    { 
            $table = "Sessions" 
            Write-Verbose "Mapped $name to $table"
        }
        ""                { 
            $table = "Not returned by observable details"
            Write-Verbose "No name provided; returning: $table"
        }
        Default           { 
            $table = $name 
            Write-Verbose "No specific mapping found; returning the original name: $table"
        }
    }

    Write-Verbose "Returning table name: $table"
    return $table
}