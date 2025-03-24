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
        Write-TriggerTroubleshooterLog "Getting table name for: $TableName with TriggerType: $TriggerType"

        # check for specific trigger type mappings
        switch ($TriggerType) {
            "UserLoggedOff" {
                Write-TriggerTroubleshooterLog "UserLoggedOff detected. Returning SessionsView table."
                return "SessionsView"
            }

            "UserLoggedOn" {
                Write-TriggerTroubleshooterLog "UserLoggedOn detected. Returning SessionsView table."
                return "SessionsView"
            }

            "WindowsEvent" {
                Write-TriggerTroubleshooterLog "UserLoggedOn detected. Returning Events table."
                return "Events"
            }   

            "ProcessStarted" {
                Write-TriggerTroubleshooterLog "UserLoggedOn detected. Returning Processes table."
                return "Processes"
            }

            "ProcessEnded" {
                Write-TriggerTroubleshooterLog "UserLoggedOn detected. Returning Processes table."
                return "Processes"
            }

            "StressLevel" {
                Write-Warning "Stress Level triggers are not implemented."
            }

            "MachineDown" {
                Write-TriggerTroubleshooterLog "MachineDown detected. Returning ComputerView table."
                return "ComputerView"
            }

            "SessionStateChanged" {
                Write-TriggerTroubleshooterLog "SessionStateChanged detected. Returning SessionsView table."
                return "SessionsView"
            }

            default {
                Write-TriggerTroubleshooterLog "No trigger type mapping found for '$TriggerType'."
            }
        }

        $table = ""
        switch ($TableName) {
            "" {
                $table = "Not returned by observable details"
                Write-TriggerTroubleshooterLog "No name provided; defaulting table name to: $table"
            }
            Default {
                $table = $TableName
                Write-TriggerTroubleshooterLog "No specific mapping for name; returning the original name: $table"
            }
        }

        Write-TriggerTroubleshooterLog "Returning table name: $table"
        return $table
    }
    catch {
        Write-TriggerTroubleshooterLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-TableName: $($_.Exception.Message)"
        throw
    }
} 