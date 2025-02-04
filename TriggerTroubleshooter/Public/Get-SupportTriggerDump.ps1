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

    Write-Verbose "Starting Get-SupportTriggerDump for TriggerName: '$Name'"
    Write-Verbose "OutputDirectory set to: '$OutputDirectory'"

    try {
        Write-Verbose "Retrieving trigger details..."
        $trigger = Get-CUTriggers | Where-Object { $_.TriggerName -eq $Name }

        if ($null -eq $trigger) {
            Write-Warning "Unable to find trigger with name '$Name'. Exiting function."
            return
        }

        Write-Verbose "Trigger found. TriggerID: $($trigger.TriggerID)"

        Write-Verbose "Creating temp directory"
        $tempRoot = [System.IO.Path]::GetTempPath()
        $tempDirectory = Join-Path -Path $tempRoot -ChildPath ([Guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDirectory | Out-Null
        Write-Verbose "Created $tempDirectory"

        $triggerDetailsPath = Join-Path -Path $tempDirectory -ChildPath "TriggerDetails.json"
        Write-Verbose "Exporting Trigger Details to '$triggerDetailsPath'"
        $triggerDetails = Get-CUTriggerDetails -TriggerId $trigger.TriggerID
        $triggerDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $triggerDetailsPath -Encoding UTF8
        Write-Verbose "Trigger Details exported successfully."

        $observableDetailsPath = Join-Path -Path $tempDirectory -ChildPath "ObservableTriggerDetails.json"
        Write-Verbose "Exporting Observable Trigger Details to '$observableDetailsPath'"
        $observableDetails = Get-CUObservableTriggerDetails -Trigger $Name
        $observableDetails | ConvertTo-Json -Depth 20 -Compress | Out-File -FilePath $observableDetailsPath -Encoding UTF8
        Write-Verbose "Observable Trigger Details exported successfully."

        Write-Verbose "Seeing what table needs to be queried"
        $table = Get-TableName -Name $observableDetails.Table -TriggerType $triggerDetails.TriggerType -RecordType $triggerDetails.AdvancedTriggerSettings.TriggerStressRecordType

        $scopedDumpPath = Join-Path -Path $tempDirectory -ChildPath "ScopedTriggerDump.json"
        Write-Verbose "Exporting Scoped Trigger Dump to '$scopedDumpPath'"
        Get-ScopedTriggerDump -Table $table -Name $Name -UseExport -TriggerObservableDetails $observableDetails -TriggerType $triggerDetails.TriggerType -Fields $triggerDetails.FilterNodes.ExpressionDescriptor.Column | ConvertTo-Json -Compress -Depth 20 | Out-File -FilePath $scopedDumpPath -Encoding UTF8
        Write-Verbose "Scoped Trigger Dump exported successfully."

        $zipFileName = "$Name.zip"
        $zipFilePath = Join-Path -Path $OutputDirectory -ChildPath $zipFileName

        Write-Verbose "Compressing dumped files into archive '$zipFilePath'"
        Compress-Archive -Path $tempDirectory -DestinationPath $zipFilePath -Force
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