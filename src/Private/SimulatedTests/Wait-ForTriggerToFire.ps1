function Wait-ForTriggerToFire {
    <#
        .SYNOPSIS
            Waits for a trigger to fire by monitoring changes in its TotalIncidents.
    
        .DESCRIPTION
            This function periodically polls trigger runtime data until the trigger's
            TotalIncidents increases or the specified timeout is reached.
    
        .PARAMETER TriggerName
            The name of the trigger to monitor.
    
        .PARAMETER Timeout
            The timeout period in seconds (default: 60).
    
        .PARAMETER Interval
            The polling interval in seconds (default: 5).
    
        .EXAMPLE
            Wait-ForTriggerToFire -TriggerName "MyTrigger" -Timeout 120 -Interval 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $TriggerName,
    
        [Parameter(Mandatory = $false)]
        [int] $Timeout = 60,
    
        [Parameter(Mandatory = $false)]
        [int] $Interval = 5
    )
  
    try {
        Write-TTLog "Starting monitoring for trigger '$TriggerName'."
        $splat = @{
            Table  = "TriggersRuntime"
            Scheme = "Runtime"
            Fields = @("Name", "TotalIncidents", "TotalInspections", "LastIncidentCreation", "LastInspection")
            Where  = "Name='$TriggerName'"
        }
    
        $initialResult = Invoke-CUQuery @splat
        if (-not $initialResult.Data) {
            Write-Error "No data returned for trigger '$TriggerName'."
            throw "Missing data for trigger '$TriggerName'."
        }
    
        $initialTotalIncidents = 0
        Write-TTLog "Initial TotalIncidents for '$TriggerName': $initialTotalIncidents"
    
        $endTime = (Get-Date).AddSeconds($Timeout)
    
        while ((Get-Date) -lt $endTime) {
            Start-Sleep -Seconds $Interval
            $currentResult = Invoke-CUQuery @splat
            if (-not $currentResult.Data) {
                Write-TTLog "No data returned during polling for '$TriggerName'; skipping iteration."
                continue
            }
    
            $currentTotalIncidents = $currentResult.Data.TotalIncidents
            Write-TTLog "Current TotalIncidents: $currentTotalIncidents, LastInspection: $($currentResult.Data.LastInspection)"
    
            if ($currentTotalIncidents -gt $initialTotalIncidents) {
                Write-TTLog "Trigger '$TriggerName' fired: TotalIncidents increased from $initialTotalIncidents to $currentTotalIncidents."
                return $true
            }
        }
    
        Write-Warning "Timeout reached. Trigger '$TriggerName' did not fire within $Timeout seconds."
        return $false
    }
    catch {
        Write-TTLog "ERROR: $($_.Exception.Message)"
        Write-Error "Error in Wait-ForTriggerToFire: $($_.Exception.Message)"
        throw
    }
}