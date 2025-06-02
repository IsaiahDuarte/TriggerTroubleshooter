function Get-TriggerConfiguration {
    <#
        .SYNOPSIS
    
        .DESCRIPTION
    
        .PARAMETER Name
            The name of the trigger
        
        .EXAMPLE
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )
  
    try {
        Write-TTLog "Getting configuration for trigger '$Name'."
        $splat = @{
            Table  = "TriggersRuntime"
            Scheme = "Runtime"
            Fields = @("Name", "TotalIncidents", "TotalInspections", "LastIncidentCreation", "LastInspection")
            Where  = "Name='$Name'"
        }
        
        $initialResult = Invoke-CUQuery @splat
        if (-not $initialResult.Data) {
            Write-Error "No data returned for trigger '$Name'."
            throw "Missing data for trigger '$Name'."
        }
        
        Write-TTLog "Found data, returning results"
        return $initialResult.Data
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Wait-ForTriggerToFire: $($_.Exception.Message)"
        throw
    }
}