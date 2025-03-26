function Get-TableName {
    <#
        .SYNOPSIS
            Retrieves the table name based on the trigger type and optional provided name. 

        .DESCRIPTION
            This function maps the trigger type and an optional provided name to a specific
            table.

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
        Write-TTLog "Getting table name for: $TableName with TriggerType: $TriggerType"

        # check for specific trigger type mappings
        switch ($TriggerType) {
            "UserLoggedOff" {
                Write-TTLog "UserLoggedOff detected. Returning SessionsView table."
                return "SessionsView"
            }

            "UserLoggedOn" {
                Write-TTLog "UserLoggedOn detected. Returning SessionsView table."
                return "SessionsView"
            }

            "WindowsEvent" {
                Write-TTLog "UserLoggedOn detected. Returning Events table."
                return "Events"
            }   

            "ProcessStarted" {
                Write-TTLog "UserLoggedOn detected. Returning Processes table."
                return "Processes"
            }

            "ProcessEnded" {
                Write-TTLog "UserLoggedOn detected. Returning Processes table."
                return "Processes"
            }

            "StressLevel" {
                Write-Warning "Stress Level triggers are not implemented."
            }

            "MachineDown" {
                Write-TTLog "MachineDown detected. Returning ComputerView table."
                return "ComputerView"
            }

            "SessionStateChanged" {
                Write-TTLog "SessionStateChanged detected. Returning SessionsView table."
                return "SessionsView"
            }

            default {
                Write-TTLog "No trigger type mapping found for '$TriggerType'."
            }
        }

        $table = ""
        switch ($TableName) {
            "" {
                $table = "Not returned by observable details"
                Write-TTLog "No name provided; defaulting table name to: $table"
            }
            Default {
                $table = $TableName
                Write-TTLog "No specific mapping for name; returning the original name: $table"
            }
        }

        Write-TTLog "Returning table name: $table"
        return $table
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-TableName: $($_.Exception.Message)"
        throw
    }
} 