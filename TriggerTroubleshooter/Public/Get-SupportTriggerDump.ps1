function Get-SupportTriggerDump {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the trigger to dump.")]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory = $false, HelpMessage = "Directory where the dump will be saved.")]
        [ValidateScript({ Test-Path $_ -PathType 'Container' })]
        [string] $OutputDirectory = $env:TEMP
    )

    Write-Verbose "Starting Get-SupportTriggerDump for TriggerName: '$TriggerName'"
    Write-Verbose "OutputDirectory set to: '$OutputDirectory'"

    try {
        Write-Verbose "Retrieving trigger details..."
        $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $TriggerName }

        if ($null -eq $trigger) {
            Write-Warning "Unable to find trigger with name '$TriggerName'. Exiting function."
            return
        }

        Write-Verbose "Trigger found. TriggerID: $($trigger.TriggerID)"

        $triggerDetailsPath = Join-Path -Path $tempDirectory -ChildPath "TriggerDetails.json"
        Write-Verbose "Exporting Trigger Details to '$triggerDetailsPath'"
        Get-CUTriggerDetails -TriggerId $trigger.TriggerID | ConvertTo-Json -Depth 20 | Out-File -FilePath $triggerDetailsPath -Encoding UTF8
        Write-Verbose "Trigger Details exported successfully."

        $observableDetailsPath = Join-Path -Path $tempDirectory -ChildPath "ObservableTriggerDetails.json"
        Write-Verbose "Exporting Observable Trigger Details to '$observableDetailsPath'"
        Get-CUObservableTriggerDetails -Trigger $TriggerName | ConvertTo-Json -Depth 20 | Out-File -FilePath $observableDetailsPath -Encoding UTF8
        Write-Verbose "Observable Trigger Details exported successfully."

        $scopedDumpPath = Join-Path -Path $tempDirectory -ChildPath "ScopedTriggerDump.json"
        Write-Verbose "Exporting Scoped Trigger Dump to '$scopedDumpPath'"
        Get-ScopedTriggerDump -Name $TriggerName | ConvertTo-Json -Depth 20 | Out-File -FilePath $scopedDumpPath -Encoding UTF8
        Write-Verbose "Scoped Trigger Dump exported successfully."

        $zipFileName = "$TriggerName.zip"
        $zipFilePath = Join-Path -Path $OutputDirectory -ChildPath $zipFileName

        Write-Verbose "Compressing dumped files into archive '$zipFilePath'"
        Compress-Archive -Path "$tempDirectory\*" -DestinationPath $zipFilePath -Force
        Write-Verbose "Compression completed successfully."

        Write-Verbose "Removing temporary directory '$tempDirectory'"
        Remove-Item -Path $tempDirectory -Recurse -Force
        Write-Verbose "Temporary directory removed successfully."

        Write-Output "Trigger dump saved to '$zipFilePath'"
    }
    catch {
        Write-Error "An error occurred during the trigger dump process: $_"
    }
}