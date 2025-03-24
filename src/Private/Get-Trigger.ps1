function Get-Trigger {
    <#
        .SYNOPSIS
            Retrieves trigger configuration data by name.

        .DESCRIPTION
            This function queries the TriggersConfiguration table within the Config scheme using Invoke-CUQuery.
            It fetches the 'Name', 'Id', and 'TriggerType' fields corresponding to the specified trigger name.

        .PARAMETER Name
            The name of the trigger to retrieve.

        .EXAMPLE
            Get-Trigger -Name "ExampleTrigger"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [string[]] $Fields = @('Name', 'Id', 'TriggerType')
    )

    try {
        Write-TriggerTroubleshooterLog "Querying triggers configuration for: $Name"
        $result = Invoke-CUQuery -Table TriggersConfiguration -Scheme Config -Fields $Fields -Where "Name='$Name'"
        if ($null -eq $result.Data) {
            Write-Warning "No data returned for trigger with name '$Name'."
            return $null
        }
        
        if($result.data.count -gt 1) {
            Write-Warning "Multiple triggers found with name $Name... exiting"
            throw "Multiple triggers found: $($Trigger.TriggerID -join ",")"
        }
        
        Write-TriggerTroubleshooterLog "Successfully retrieved trigger data."
        return $result.Data
    }
    catch {
        Write-TriggerTroubleshooterLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Get-Trigger: $($_.Exception.Message)"
        throw
    }
}