function Get-TableName {
    <#
    .SYNOPSIS
        Retrieves the table name based on the trigger type and optional provided name. 

    .DESCRIPTION
        This function maps the trigger type and an optional provided name to a specific database
        table (or view) name. For example, if the trigger type is "UserLoggedOff", it returns the
        "SessionsView" table. If no specific mapping is found based on the name, it returns the name
        provided, or a default message if no name is given.

    .PARAMETER TriggerType
        Specifies the type of trigger (e.g., "UserLoggedOff"). This parameter is mandatory.

    .PARAMETER Name
        An optional name parameter that can be used to further determine the table mapping.

    .EXAMPLE
        Get-TableName -TriggerType "UserLoggedOff" -Name "SomeName"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TriggerType,

        [Parameter(Mandatory = $false)]
        [string] $Name
    )

    try {
        Write-Verbose "Getting table name for: $Name with TriggerType: $TriggerType"

        # check for specific trigger type mappings
        switch ($TriggerType) {
            "UserLoggedOff" {
                Write-Verbose "UserLoggedOff detected. Returning SessionsView table."
                return "SessionsView"
            }

            "UserLoggedOn" {
                Write-Verbose "UserLoggedOn detected. Returning SessionsView table."
                return "SessionsView"
            }

            "WindowsEvent" {
                Write-Verbose "UserLoggedOn detected. Returning SessionsView table."
                return "Events"
            }

            default {
                Write-Verbose "No trigger type mapping found for '$TriggerType'."
            }
        }

        # Determine table name based on the provided Name parameter
        $table = ""
        switch ($Name) {
            "" {
                $table = "Not returned by observable details"
                Write-Verbose "No name provided; defaulting table name to: $table"
            }
            Default {
                $table = $Name
                Write-Verbose "No specific mapping for name; returning the original name: $table"
            }
        }

        Write-Verbose "Returning table name: $table"
        return $table
    }
    catch {
        Write-Error "Error in Get-TableName: $($_.Exception.Message)"
        throw
    }
} 