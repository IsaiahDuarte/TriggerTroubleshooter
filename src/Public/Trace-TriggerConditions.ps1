function Trace-TriggerConditions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$false)]
        [timespan] $Duration = (New-TimeSpan -Minutes 1) 
    )
    try {

        Write-Verbose "Getting Trigger"
        $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $Name }
        if (-not $trigger) {
            Write-Warning "Trigger with name '$Name' not found."
            return
        }
        Write-Verbose "Trigger found: $trigger"

        Write-Verbose "Getting trigger configuration"
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerId


        Write-Verbose "Getting Trigger Observable Details"
        $triggerObservableDetails = Get-CUObservableTriggerDetails -Trigger $Name
    
        Write-Verbose "Getting the Table"
        $table = Get-TableName -TableName $triggerObservableDetails.Table -TriggerType $triggerDetails.TriggerType    

        
    } catch {
        Write-Error -Message "Error in Trace-TriggerConditions: $($_.Exception.Message)" -ErrorAction Stop
    }


}