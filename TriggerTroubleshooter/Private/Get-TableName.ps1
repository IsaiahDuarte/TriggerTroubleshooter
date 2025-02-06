function Get-TableName {
    <#
    .SYNOPSIS
        Retrieves the table name based on the trigger type and optional provided name. 

    .DESCRIPTION
        This function maps the trigger type and an optional provided name to a specific
        table. For example, if the trigger type is "UserLoggedOff", it returns the
        "SessionsView" table. If no specific mapping is found based on the name, it returns the name
        provided, or a default message if no name is given.

    .PARAMETER TriggerType
        Specifies the type of trigger (e.g., "UserLoggedOff"). This parameter is mandatory.

    .PARAMETER TableName
        Expects table from TriggerObservableDetails if returned

    .EXAMPLE
        Get-TableName -TriggerType "UserLoggedOff" -Name "SessionsView"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TriggerType,

        [Parameter(Mandatory = $false)]
        [string] $TableName
    )

    try {
        Write-Verbose "Getting table name for: $TableName with TriggerType: $TriggerType"

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
                Write-Verbose "UserLoggedOn detected. Returning Events table."
                return "Events"
            }

            "ProcessStarted" {
                Write-Verbose "UserLoggedOn detected. Returning Processes table."
                return "Processes"
            }

            "ProcessEnded" {
                Write-Verbose "UserLoggedOn detected. Returning Processes table."
                return "Processes"
            }

            "StressLevel" {
                Write-Warning "Stress Level triggers are not implemented."
            }

            "MachineDown" {
                Write-Verbose "MachineDown detected. Returning ComputerView table."
                return "ComputerView"
            }

            "SessionStateChanged" {
                Write-Verbose "SessionStateChanged detected. Returning SessionsView table."
                return "SessionsView"
            }

            default {
                Write-Verbose "No trigger type mapping found for '$TriggerType'."
            }
        }

        $table = ""
        switch ($TableName) {
            "" {
                $table = "Not returned by observable details"
                Write-Verbose "No name provided; defaulting table name to: $table"
            }
            Default {
                $table = $TableName
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