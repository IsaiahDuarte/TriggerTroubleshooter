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
        [string] $Name
    )

    try {
        Write-Verbose "Querying triggers configuration for: $Name"
        $result = Invoke-CUQuery -Table TriggersConfiguration -Scheme Config -Fields @('Name', 'Id', 'TriggerType') -Where "Name='$Name'"
        if ($null -eq $result.Data) {
            Write-Warning "No data returned for trigger with name '$Name'."
            return $null
        }
        Write-Verbose "Successfully retrieved trigger data."
        return $result.Data
    }
    catch {
        Write-Error "Error in Get-Trigger: $($_.Exception.Message)"
        throw
    }
}