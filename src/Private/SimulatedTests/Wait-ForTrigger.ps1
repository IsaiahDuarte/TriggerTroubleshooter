function Wait-ForTrigger {
    <#
    .SYNOPSIS
        Waits for a trigger to appear or disappear within a specified time.
    
    .DESCRIPTION
        Polls the 'TriggersConfiguration' table for the given trigger name until it appears 
        (if -ShouldExist is specified) or disappears (if not specified) within the timeout period.
    
    .PARAMETER TriggerName
        The name of the trigger to monitor. Mandatory.
    
    .PARAMETER TimeoutSeconds
        The maximum number of seconds to poll. Defaults to 30.
    
    .PARAMETER PollIntervalSeconds
        The interval in seconds between polls. Defaults to 5.
    
    .PARAMETER ShouldExist
        Switch indicating that the trigger is expected to appear. If not specified, the function
        waits for the trigger to be absent.
    
    .EXAMPLE
        Wait-ForTrigger -TriggerName "MyTrigger" -TimeoutSeconds 60 -PollIntervalSeconds 10 -ShouldExist
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $TriggerName,
    
        [Parameter()]
        [int] $TimeoutSeconds = 30,
    
        [Parameter()]
        [int] $PollIntervalSeconds = 5,
    
        [Parameter()]
        [Switch] $ShouldExist
    )
    
    # Start a timer for the timeout period
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        Write-TriggerTroubleshooterLog "Polling for trigger '$TriggerName' with Timeout: $TimeoutSeconds seconds and Poll Interval: $PollIntervalSeconds seconds. ShouldExist: $ShouldExist"
            
        do {
            Write-TriggerTroubleshooterLog "Invoking query for trigger '$TriggerName'. Elapsed time: $($stopwatch.Elapsed.TotalSeconds) seconds."
            $queryResult = Invoke-CUQuery -Scheme 'Config' -Table 'TriggersConfiguration' -Fields @("Name", "Id") -Where "Name='$TriggerName'"
    
            $triggerExists = ($queryResult.Total -gt 0)
            Write-TriggerTroubleshooterLog "Trigger existence check: $triggerExists"
    
            if ($ShouldExist.IsPresent -and $triggerExists) {
                Write-TriggerTroubleshooterLog "Trigger '$TriggerName' found. Returning associated data."
                return $queryResult.Data
            }
            elseif (-not $ShouldExist.IsPresent -and -not $triggerExists) {
                Write-TriggerTroubleshooterLog "Trigger '$TriggerName' not found. Returning true."
                return $true
            }
    
            Start-Sleep -Seconds $PollIntervalSeconds
    
        } while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds)
    
        if ($ShouldExist.IsPresent) {
            Write-Warning "Trigger '$TriggerName' did not appear within the timeout period ($TimeoutSeconds seconds)."
            return $null
        }
        else {
            Write-Warning "Trigger '$TriggerName' is still present after the timeout period ($TimeoutSeconds seconds)."
            return $false
        }
    }
    catch {
        Write-Error "Error in Wait-ForTrigger: $($_.Exception.Message)"
        throw
    }
}