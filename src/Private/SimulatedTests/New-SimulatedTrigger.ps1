function New-SimulatedTrigger {
    param(
        [Parameter(Mandatory)] [hashtable] $NewTriggerProps,  # Splat for Add-CUTrigger
        [Parameter(Mandatory)] [psobject]  $Computer,
        [Parameter(Mandatory)] [string]    $TriggerName,
        [Parameter(Mandatory)] [string]    $ActionParams,
        [Parameter()]          [int]       $Timeout = 30
    )

    Write-TTLog "Creating new trigger '$TriggerName'."
    Write-TTLog ($NewTriggerProps | ConvertTo-Json -Depth 20)
    $addedTrigger = Add-CUTrigger @NewTriggerProps

    # Wait until the new trigger is visible in the environment
    Wait-ForTrigger -TriggerName $TriggerName -ShouldExist | Out-Null

    # Retrieve the “Trigger Troubleshooter - Simulated Test” script action 
    $action = Get-CUAvailableActions -DisplayName "Trigger Troubleshooter - Simulated Test"
    if (-not $action) {
        Write-Warning "Unable to find Trigger Troubleshooter - Simulated Test script action."
        throw "Missing Script Action"
    }

    Write-TTLog "Preparing to invoke action '$($action.Title)'."
    Write-TTLog "UserInput JSON: $ActionParams"
    $actionResult = Invoke-CUAction -ActionId $action.ID -Table $action.Table `
                                    -RecordsGuids $Computer.Key -UserInput $ActionParams
    if ($actionResult.Result -eq 'Error') {
        Write-Error $actionResult.ErrorMessage
        throw "Action invocation failed: $($actionResult.ErrorMessage)"
    }

    Write-TTLog "Waiting for the new trigger to fire (Timeout = $Timeout)."
    $didTriggerFire = Wait-ForTriggerToFire -TriggerName $TriggerName -Timeout $Timeout
    Write-TTLog "Trigger Fired: $didTriggerFire"

    return @{
        TriggerObject = $addedTrigger
        Fired         = $didTriggerFire
    }
}
